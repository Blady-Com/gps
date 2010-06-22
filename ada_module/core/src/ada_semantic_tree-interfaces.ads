-----------------------------------------------------------------------
--                               G P S                               --
--                                                                   --
--                  Copyright (C) 2009-2010, AdaCore                 --
--                                                                   --
-- GPS is free  software;  you can redistribute it and/or modify  it --
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

with GNAT.Strings;  use GNAT.Strings;

package Ada_Semantic_Tree.Interfaces is

   procedure Register_Assistant (Db : Construct_Database_Access);
   --  This assistant has to be registered to the database before any of the
   --  queries in this file can work.

   function Get_Assistant
     (Db : Construct_Database_Access) return Database_Assistant_Access;
   --  Return assistant holding the knowledge about the interfaces pragmas

   function Get_Exported_Entity
     (Assistant : Database_Assistant_Access; Name : String)
      return Entity_Access;
   --  Return the entity exported to this name, Null_Entity_Access if none.

   type Imported_Entity is private;
   --  Type representing this entity imported data. This should not be stored
   --  for a long time, as its contents will be invalidated at each construct
   --  file update.

   Null_Imported_Entity : aliased constant Imported_Entity;

   function Get_Imported_Entity
     (Entity : Entity_Access) return Imported_Entity;
   --  Return the imported entity by this entity, Null_Imported_Entity if none.

   function Get_Name (Entity : Imported_Entity) return String;
   --  Return the imported name of the entity.

   function Get_Convention (Entity : Imported_Entity) return String;
   --  Return the convention from which the entity is imported

private

   type Imported_Entity is record
      Name       : String_Access;
      Convention : String_Access;
   end record;

   Null_Imported_Entity : aliased constant Imported_Entity := (null, null);

end Ada_Semantic_Tree.Interfaces;
