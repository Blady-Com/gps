-----------------------------------------------------------------------
--                   GVD - The GNU Visual Debugger                   --
--                                                                   --
--                      Copyright (C) 2000-2001                      --
--                              ACT-Europe                           --
--                                                                   --
-- GVD is free  software;  you can redistribute it and/or modify  it --
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

with Gtk.Widget;       use Gtk.Widget;
with Gtk.Check_Button; use Gtk.Check_Button;
with Basic_Types;      use Basic_Types;
with Open_Session_Pkg; use Open_Session_Pkg;

package GVD.Session_Dialog is

   type Button_Node;
   type Button_Link is access Button_Node;

   type Button_Node is record
      Next   : Button_Link;
      Button : Gtk_Check_Button;
      Label  : String_Access;
   end record;

   type GVD_Session_Dialog_Record is new Open_Session_Record with record
      Sessions_Dir : String_Access;
      First_Button : Button_Link := null;
      Lock_Buttons : Boolean := False;
   end record;
   type GVD_Session_Dialog is access all GVD_Session_Dialog_Record'Class;

   procedure Create_Buttons
     (Open      : access GVD_Session_Dialog_Record'Class;
      File_Name : String);
   --  Add all the check_buttons corresponding to the session information.

   procedure Remove_All_Buttons
     (Open : access GVD_Session_Dialog_Record'Class);
   --  Clear all the check_buttons.

   ----------------------
   -- Session Handling --
   ----------------------

   --  The format for session files is as follows:
   --
   --  [Session_File Header]
   --  <number_of_processes>
   --  ---------------------
   --      <program_file_name_1>
   --      <debugger_type_1>
   --      <remote_host_1>
   --      <remote_target_1>
   --      <protocol_1>
   --      <debugger_name_1>
   --  ---------------------
   --      <program_file_name_2>
   --      <debugger_type_2>
   --      <remote_host_2>
   --      <remote_target_2>
   --      <protocol_2>
   --      <debugger_name_2>
   --  (etc)
   --  [History]
   --    <debugger_number> < H | V | U > <command>
   --    <debugger_number> < H | V | U > <command>
   --  (etc)
   --  ---------------------

   procedure Open_Session
     (Window : access Gtk_Widget_Record'Class;
      Open   : in out GVD_Session_Dialog;
      Dir    : String);
   --  Load a session into Gvd. Window is the main debug window.

   procedure Save_Session
     (Window : access Gtk_Widget_Record'Class;
      Open   : in out GVD_Session_Dialog;
      Dir    : String);
   --  Save a session. Window is the main debug window.

end GVD.Session_Dialog;
