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

--  with Gtk.Arguments;
with Gtk.Widget; use Gtk.Widget;

package New_Variable_Editor_Pkg.Callbacks is
   procedure On_Variable_Name_Changed
     (Object : access Gtk_Widget_Record'Class);

   procedure On_Get_Environment_Toggled
     (Object : access Gtk_Widget_Record'Class);

   procedure On_Env_Must_Be_Defined_Toggled
     (Object : access Gtk_Widget_Record'Class);

   procedure On_Typed_Variable_Toggled
     (Object : access Gtk_Widget_Record'Class);

   procedure On_Enumeration_Value_Changed
     (Object : access Gtk_Widget_Record'Class);

   procedure On_Add_Clicked
     (Object : access Gtk_Widget_Record'Class);

   procedure On_Cancel_Clicked
     (Object : access Gtk_Widget_Record'Class);

end New_Variable_Editor_Pkg.Callbacks;
