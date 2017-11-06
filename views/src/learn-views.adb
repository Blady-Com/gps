------------------------------------------------------------------------------
--                                  G P S                                   --
--                                                                          --
--                     Copyright (C) 2017, AdaCore                          --
--                                                                          --
-- This is free software;  you can redistribute it  and/or modify it  under --
-- terms of the  GNU General Public License as published  by the Free Soft- --
-- ware  Foundation;  either version 3,  or (at your option) any later ver- --
-- sion.  This software is distributed in the hope  that it will be useful, --
-- but WITHOUT ANY WARRANTY;  without even the implied warranty of MERCHAN- --
-- TABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public --
-- License for  more details.  You should have  received  a copy of the GNU --
-- General  Public  License  distributed  with  this  software;   see  file --
-- COPYING3.  If not, go to http://www.gnu.org/licenses for a complete copy --
-- of the license.                                                          --
------------------------------------------------------------------------------

with Ada.Containers.Doubly_Linked_Lists;

with Gtk.Box;           use Gtk.Box;
with Gtk.Enums;         use Gtk.Enums;
with Gtk.Style_Context; use Gtk.Style_Context;
with Gtk.Widget;        use Gtk.Widget;
with Gtkada.Handlers;   use Gtkada.Handlers;
with Gtkada.MDI;        use Gtkada.MDI;

with Dialog_Utils;      use Dialog_Utils;
with Generic_Views;     use Generic_Views;
with GPS.Kernel.Hooks;  use GPS.Kernel.Hooks;
with GPS.Kernel.MDI;    use GPS.Kernel.MDI;

package body Learn.Views is

   package Group_Widget_Lists is new Ada.Containers.Doubly_Linked_Lists
        (Element_Type => Dialog_Group_Widget,
         "="          => "=");

   type Learn_View_Record is new Generic_Views.View_Record with record
         Main_View     : Dialog_View;
         Group_Widgets : Group_Widget_Lists.List;
   end record;
   type Learn_View is access all Learn_View_Record'Class;

   function Initialize
     (View : access Learn_View_Record'Class) return Gtk.Widget.Gtk_Widget;

   package Generic_Learn_Views is new Generic_Views.Simple_Views
     (Module_Name        => "Learn_View",
      View_Name          => "Learn",
      Reuse_If_Exist     => True,
      Local_Toolbar      => True,
      Local_Config       => True,
      Areas              => Gtkada.MDI.Sides_Only,
      Formal_MDI_Child   => GPS_MDI_Child_Record,
      Formal_View_Record => Learn_View_Record);

   function Filter_Learn_Item
     (Child : not null access Gtk_Flow_Box_Child_Record'Class) return Boolean;
   --  Called each time we want to refilter the learn items contained in the
   --  Learn view.

   procedure Child_Selected (Self : access Gtk_Widget_Record'Class);
   --  Called each time the selected MDI child changes

   -----------------------
   -- Filter_Learn_Item --
   -----------------------

   function Filter_Learn_Item
     (Child : not null access Gtk_Flow_Box_Child_Record'Class) return Boolean
   is
      Item   : constant Learn_Item := Learn_Item (Child);
      Kernel : constant Kernel_Handle :=
                 Generic_Learn_Views.Get_Module.Get_Kernel;
   begin
      return Item.Is_Visible (Kernel.Get_Current_Context, Filter_Text => "");
   end Filter_Learn_Item;

   --------------------
   -- Child_Selected --
   --------------------

   procedure Child_Selected (Self : access Gtk_Widget_Record'Class) is
      View : constant Learn_View := Learn_View (Self);
   begin
      for Group_Widget of View.Group_Widgets loop
         Group_Widget.Force_Refilter;
      end loop;
   end Child_Selected;

   ----------------
   -- Initialize --
   ----------------

   function Initialize
     (View : access Learn_View_Record'Class) return Gtk.Widget.Gtk_Widget
   is
      Providers    : constant Learn_Provider_Maps.Map :=
                       Get_Registered_Providers;
      Group_Widget : Dialog_Group_Widget;
   begin
      Initialize_Vbox (View);

      --  Connect to the Signal_Child_Selected signal to refilter all the
      --  learn intems contained in the view.

      Widget_Callback.Object_Connect
        (Get_MDI (View.Kernel), Signal_Child_Selected,
         Widget_Callback.To_Marshaller (Child_Selected'Access), View);

      --  Create the main view

      View.Main_View := new Dialog_View_Record;
      Dialog_Utils.Initialize (View.Main_View);
      View.Pack_Start (View.Main_View);

      --  Create a group widget for all the registered providers

      for Provider of Providers loop
         Group_Widget := new Dialog_Group_Widget_Record;
         View.Group_Widgets.Append (Group_Widget);

         Initialize
           (Self                => Group_Widget,
            Parent_View         => View.Main_View,
            Group_Name          => Provider.Get_Name,
            Allow_Multi_Columns => False,
            Selection           => Selection_Single,
            Filtering_Function  => Filter_Learn_Item'Access);

         Get_Style_Context (Group_Widget).Add_Class ("learn-groups");

         --  Add the provider's learn items in the group widget

         for Item of Provider.Get_Learn_Items loop
            Get_Style_Context (Item).Add_Class ("learn-items");
            Group_Widget.Append_Child
              (Widget    => Item,
               Expand    => False);
         end loop;
      end loop;

      return Gtk_Widget (View);
   end Initialize;

   ---------------------
   -- Register_Module --
   ---------------------

   procedure Register_Module
     (Kernel : access GPS.Kernel.Kernel_Handle_Record'Class)
   is
   begin
      Generic_Learn_Views.Register_Module (Kernel);
   end Register_Module;

end Learn.Views;
