------------------------------------------------------------------------------
--                                  G P S                                   --
--                                                                          --
--                     Copyright (C) 2010-2013, AdaCore                     --
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

with Glib;                       use Glib;
with GNATCOLL.VFS.GtkAda;        use GNATCOLL.VFS, GNATCOLL.VFS.GtkAda;
with GPS.Kernel.Messages;        use GPS.Kernel.Messages;
with GPS.Location_View.Listener; use GPS.Location_View.Listener;

package body GPS.Location_View_Sort is

   type Compare_Functions is
     array (Positive range <>) of Gtk_Tree_Iter_Compare_Func;

   function Compare
     (Model : Gtk_Tree_Model;
      A     : Gtk_Tree_Iter;
      B     : Gtk_Tree_Iter;
      Funcs : Compare_Functions) return Gint;
   --  General compare function, it compares A and B using Funcs till
   --  nonequvalence is reported or end of Funcs is reached.

   function Compare_In_Base_Name_Order
     (Model : Gtk_Tree_Model;
      A     : Gtk_Tree_Iter;
      B     : Gtk_Tree_Iter) return Gint;
   --  Compare files of A and B in base name order.

   function Compare_In_Line_Column_Order
     (Model : Gtk_Tree_Model;
      A     : Gtk_Tree_Iter;
      B     : Gtk_Tree_Iter) return Gint;
   --  Compare message of A and B in line:column order.

   function Compare_In_Weight_Order
     (Model : Gtk_Tree_Model;
      A     : Gtk_Tree_Iter;
      B     : Gtk_Tree_Iter) return Gint;
   --  Compare nodes A and B in weight order.

   function Compare_In_Path_Order
     (Model : Gtk_Tree_Model;
      A     : Gtk_Tree_Iter;
      B     : Gtk_Tree_Iter) return Gint;
   --  Compare A and B in path order.

   function Compare_By_Location
     (Self : Gtk_Tree_Model;
      A    : Gtk_Tree_Iter;
      B    : Gtk_Tree_Iter) return Gint;
   --  Compares rows in locations order

   function Compare_By_Weight
     (Self : Gtk_Tree_Model;
      A    : Gtk_Tree_Iter;
      B    : Gtk_Tree_Iter) return Gint;
   --  Compares rows in weight order first

   -------------
   -- Compare --
   -------------

   function Compare
     (Model : Gtk_Tree_Model;
      A     : Gtk_Tree_Iter;
      B     : Gtk_Tree_Iter;
      Funcs : Compare_Functions) return Gint
   is
      Result : Gint := 0;

   begin
      for J in Funcs'Range loop
         Result := Funcs (J) (Model, A, B);

         exit when Result /= 0;
      end loop;

      return Result;
   end Compare;

   -------------------------
   -- Compare_By_Location --
   -------------------------

   function Compare_By_Location
     (Self : Gtk_Tree_Model;
      A    : Gtk_Tree_Iter;
      B    : Gtk_Tree_Iter) return Gint
   is
      Path  : constant Gtk_Tree_Path := Get_Path (Self, A);
      Depth : constant Natural := Natural (Get_Depth (Path));

   begin
      --  GtkTreeSortModel breaks underlying order of equal rows, so return
      --  result of compare of last indices to save underlying order.

      Path_Free (Path);

      if Depth = 2 then
         --  File level node

         case Sort_Order_Hint'Val
           (Get_Int (Self, A, Sort_Order_Hint_Column))
         is
            when Chronological =>
               return Compare_In_Path_Order (Self, A, B);

            when Alphabetical =>
               return
                 Compare
                   (Self,
                    A,
                    B,
                    (Compare_In_Base_Name_Order'Access,
                     Compare_In_Path_Order'Access));
         end case;

      elsif Depth = 3 then
         --  Message level node

         return
           Compare
             (Self,
              A,
              B,
              (Compare_In_Line_Column_Order'Access,
               Compare_In_Path_Order'Access));

      else
         return Compare_In_Path_Order (Self, A, B);
      end if;
   end Compare_By_Location;

   -----------------------
   -- Compare_By_Weight --
   -----------------------

   function Compare_By_Weight
     (Self : Gtk_Tree_Model;
      A    : Gtk.Tree_Model.Gtk_Tree_Iter;
      B    : Gtk.Tree_Model.Gtk_Tree_Iter) return Gint
   is
      Path     : constant Gtk_Tree_Path := Get_Path (Self, A);
      Depth    : Natural;

   begin
      --  GtkTreeSortModel breaks underling order of equal rows, so return
      --  result of compare of last indices to save underling order.

      Depth := Natural (Get_Depth (Path));
      Path_Free (Path);

      if Depth = 2 then
         --  File level node

         case Sort_Order_Hint'Val
           (Get_Int (Self, A, Sort_Order_Hint_Column))
         is
            when Chronological =>
               return
                 Compare
                   (Self,
                    A,
                    B,
                    (Compare_In_Weight_Order'Access,
                     Compare_In_Path_Order'Access));

            when Alphabetical =>
               return
                 Compare
                   (Self,
                    A,
                    B,
                    (Compare_In_Weight_Order'Access,
                     Compare_In_Base_Name_Order'Access,
                     Compare_In_Path_Order'Access));
         end case;

      elsif Depth = 3 then
         --  Message level node

         return
           Compare
             (Self,
              A,
              B,
              (Compare_In_Weight_Order'Access,
               Compare_In_Line_Column_Order'Access,
               Compare_In_Path_Order'Access));

      else
         return Compare_In_Path_Order (Self, A, B);
      end if;
   end Compare_By_Weight;

   --------------------------------
   -- Compare_In_Base_Name_Order --
   --------------------------------

   function Compare_In_Base_Name_Order
     (Model : Gtk_Tree_Model;
      A     : Gtk_Tree_Iter;
      B     : Gtk_Tree_Iter) return Gint
   is
      A_Name : constant Filesystem_String :=
                 Get_File (Model, A, File_Column).Base_Name;
      B_Name : constant Filesystem_String :=
                 Get_File (Model, B, File_Column).Base_Name;

   begin
      if A_Name < B_Name then
         return -1;

      elsif A_Name = B_Name then
         return 0;

      else
         return 1;
      end if;
   end Compare_In_Base_Name_Order;

   ----------------------------------
   -- Compare_In_Line_Column_Order --
   ----------------------------------

   function Compare_In_Line_Column_Order
     (Model : Gtk_Tree_Model;
      A     : Gtk_Tree_Iter;
      B     : Gtk_Tree_Iter) return Gint
   is
      A_Line   : constant Gint := Get_Int (Model, A, Line_Column);
      A_Column : constant Gint := Get_Int (Model, A, Column_Column);
      B_Line   : constant Gint := Get_Int (Model, B, Line_Column);
      B_Column : constant Gint := Get_Int (Model, B, Column_Column);

   begin
      if A_Line < B_Line then
         return -1;

      elsif A_Line = B_Line then
         if A_Column < B_Column then
            return -1;

         elsif A_Column = B_Column then
            return 0;
         end if;
      end if;

      return 1;
   end Compare_In_Line_Column_Order;

   ---------------------------
   -- Compare_In_Path_Order --
   ---------------------------

   function Compare_In_Path_Order
     (Model : Gtk_Tree_Model;
      A     : Gtk_Tree_Iter;
      B     : Gtk_Tree_Iter) return Gint
   is
      A_Path    : constant Gtk_Tree_Path := Get_Path (Model, A);
      B_Path    : constant Gtk_Tree_Path := Get_Path (Model, B);
      A_Indices : constant Gint_Array := Get_Indices (A_Path);
      B_Indices : constant Gint_Array := Get_Indices (B_Path);

   begin
      Path_Free (A_Path);
      Path_Free (B_Path);

      if A_Indices (A_Indices'Last) < B_Indices (B_Indices'Last) then
         return -1;

      elsif A_Indices (A_Indices'Last) = B_Indices (B_Indices'Last) then
         return 0;

      else
         return 1;
      end if;
   end Compare_In_Path_Order;

   -----------------------------
   -- Compare_In_Weight_Order --
   -----------------------------

   function Compare_In_Weight_Order
     (Model : Gtk_Tree_Model;
      A     : Gtk_Tree_Iter;
      B     : Gtk_Tree_Iter) return Gint
   is
      A_Weight : constant Gint := Get_Int (Model, A, Weight_Column);
      B_Weight : constant Gint := Get_Int (Model, B, Weight_Column);

   begin
      if A_Weight > B_Weight then
         return -1;

      elsif A_Weight = B_Weight then
         return 0;

      else
         return 1;
      end if;
   end Compare_In_Weight_Order;

   -------------
   -- Gtk_New --
   -------------

   procedure Gtk_New
     (Model  : in out Locations_Proxy_Model;
      Source : not null access Gtk_Root_Tree_Model_Record'Class) is
   begin
      Model := new Locations_Proxy_Model_Record;
      Gtk.Tree_Model_Sort.Initialize_With_Model
        (Model, Child_Model => To_Interface (Source));
      Model.Set_Order (By_Location);
   end Gtk_New;

   ---------------
   -- Set_Order --
   ---------------

   procedure Set_Order
     (Self  : not null access Locations_Proxy_Model_Record'Class;
      Order : Sort_Order)
   is
   begin
      case Order is
         when By_Location =>
            Self.Set_Default_Sort_Func (Compare_By_Location'Access);

         when By_Weight =>
            Self.Set_Default_Sort_Func (Compare_By_Weight'Access);
      end case;
   end Set_Order;

end GPS.Location_View_Sort;