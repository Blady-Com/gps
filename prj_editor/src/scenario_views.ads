-----------------------------------------------------------------------
--                          G L I D E  I I                           --
--                                                                   --
--                        Copyright (C) 2001                         --
--                            ACT-Europe                             --
--                                                                   --
-- GLIDE is free software; you can redistribute it and/or modify  it --
-- under the terms of the GNU General Public License as published by --
-- the Free Software Foundation; either version 2 of the License, or --
-- (at your option) any later version.                               --
--                                                                   --
-- This program is  distributed in the hope that it will be  useful, --
-- but  WITHOUT ANY WARRANTY;  without even the  implied warranty of --
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU --
-- General Public License for more details. You should have received --
-- a copy of the GNU General Public License along with this library; --
-- if not,  write to the  Free Software Foundation, Inc.,  59 Temple --
-- Place - Suite 330, Boston, MA 02111-1307, USA.                    --
-----------------------------------------------------------------------

--  <description>
--
--  This widget presents a summary view of the current scenario (see
--  definition in prj_manager.ads). It also provides various ways to
--  change or edit this scenario.
--
--  </description>

with Gdk.Bitmap;
with Gdk.Pixmap;
with Gtk.Table;
with Glide_Kernel;

package Scenario_Views is

   type Scenario_View_Record is new Gtk.Table.Gtk_Table_Record with private;
   type Scenario_View is access all Scenario_View_Record'Class;

   procedure Gtk_New
     (View    : out Scenario_View;
      Kernel  : access Glide_Kernel.Kernel_Handle_Record'Class);
   --  Create a new scenario view associated with Manager.
   --  The view is automatically refreshed every time the project view in
   --  the manager changes.

   procedure Initialize
     (View    : access Scenario_View_Record'Class;
      Kernel  : access Glide_Kernel.Kernel_Handle_Record'Class);
   --  Internal function for creating new widgets

private
   type Scenario_View_Record is new Gtk.Table.Gtk_Table_Record with record
      Kernel      : Glide_Kernel.Kernel_Handle;

      Edit_Pixmap   : Gdk.Pixmap.Gdk_Pixmap;
      Edit_Mask     : Gdk.Bitmap.Gdk_Bitmap;
      Delete_Pixmap : Gdk.Pixmap.Gdk_Pixmap;
      Delete_Mask   : Gdk.Bitmap.Gdk_Bitmap;

      Combo_Is_Open : Boolean := False;
      --  Flag temporarily set to True when a user is modifying the value of
      --  one of the scenario variable through the combo boxes.
   end record;
end Scenario_Views;
