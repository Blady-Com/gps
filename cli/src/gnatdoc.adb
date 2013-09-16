------------------------------------------------------------------------------
--                                  G P S                                   --
--                                                                          --
--                     Copyright (C) 2013, AdaCore                          --
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

--  Command line docgen utility

with Ada.Command_Line;
with Ada.Text_IO;       use Ada.Text_IO;

with GNAT.Command_Line; use GNAT.Command_Line;
with GNAT.Strings;      use GNAT.Strings;

with GNATCOLL.Traces;   use GNATCOLL.Traces;
with GNATCOLL.VFS;      use GNATCOLL.VFS;

with GPS.CLI_Utils;     use GPS.CLI_Utils;
with GPS.CLI_Kernels;   use GPS.CLI_Kernels;

with Docgen3;
with Xref;              use Xref;

procedure GNATdoc is

   Cmdline               : Command_Line_Configuration;
   Project_Name          : aliased GNAT.Strings.String_Access;
   Project_File          : Virtual_File;
   Kernel                : constant GPS.CLI_Kernels.CLI_Kernel :=
     new GPS.CLI_Kernels.CLI_Kernel_Record;

begin
   --  Retrieve log configuration
   GNATCOLL.Traces.Parse_Config_File;

   --  Set comand line options
   Set_Usage
     (Cmdline,
      Help => "Docgen command line interface");

   Define_Switch
     (Cmdline,
      Output      => Project_Name'Access,
      Switch      => "-P:",
      Long_Switch => "--project=",
      Help        => "Load the given project (mandatory)");
   Define_Switch
     (Cmdline,
      Switch       => "-X:",
      Help         => "Specify an external reference in the project");

   --  Initialize context
   GPS.CLI_Utils.Create_Kernel_Context (Kernel);

   --  Retrieve command line option
   begin
      GPS.CLI_Utils.Parse_Command_Line (Cmdline, Kernel);
   exception
      when GNAT.Command_Line.Exit_From_Command_Line =>
         --  User provided -h or --help option. Just return
         return;
   end;

   --  Check project file path passed in command line
   --  Exit with message if no project file path found at all
   if not GPS.CLI_Utils.Is_Project_Path_Specified (Project_Name) then
      Put_Line ("No project file specified");
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
      return;
   end if;

   --  Exit with message if path is not valid
   if not GPS.CLI_Utils.Project_File_Path_Exists (Project_Name) then
      Put_Line ("No such file: " & Project_Name.all);
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
      return;
   end if;

   Project_File := Create (+Project_Name.all);

   --  Load project
   Kernel.Registry.Tree.Load
     (Root_Project_Path => Project_File,
      Env               => Kernel.Registry.Environment);

   Project_Changed (Kernel.Databases);
   Project_View_Changed (Kernel.Databases, Kernel.Registry.Tree);

   --  Run Docgen
   declare
      Options : Docgen3.Docgen_Options;
   begin
      Docgen3.Process_Project_Files
        (Kernel    => Kernel,
         Options   => Options,
         Project   => Kernel.Registry.Tree.Root_Project,
         Recursive => True);
   end;

   --  Destroy all
   GPS.CLI_Utils.Destroy_Kernel_Context (Kernel);

end GNATdoc;