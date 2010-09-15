-----------------------------------------------------------------------
--                               G P S                               --
--                                                                   --
--                      Copyright (C) 2010, AdaCore                  --
--                                                                   --
-- GPS is free  software; you can  redistribute it and/or modify  it --
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

--  Gtk/GUI support for Project templates
--  NOTE: this should remain independent from the GPS Kernel, so that
--  it can be reused in a stand-alone executable.

with Gdk.Pixbuf; use Gdk.Pixbuf;

package Project_Templates.GUI is

   procedure Install_Template
     (Templates    : Project_Templates_List.List;
      Header_Image : Gdk_Pixbuf;
      Chosen       : out Project_Template;
      Installed    : out Boolean;
      Dir          : out Virtual_File;
      Project      : out Virtual_File;
      Errors       : out Unbounded_String);
   --  Read templates in Templates, offer a dialog to select a template and
   --  fill in the fields, and select a target directory.
   --  If the user validates the choice, then install the template in the
   --  selected location, and Installed is set to True, Dir contains
   --  the target directory, Project the deployed project file, and
   --  Chosen the chosen template.
   --  If any errors are encountered, they are listed in Errors.

end Project_Templates.GUI;
