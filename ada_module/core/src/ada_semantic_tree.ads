-----------------------------------------------------------------------
--                               G P S                               --
--                                                                   --
--                  Copyright (C) 2007-2010, AdaCore                 --
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
-- a copy of the GNU General Public License along with this program; --
-- if not,  write to the  Free Software Foundation, Inc.,  59 Temple --
-- Place - Suite 330, Boston, MA 02111-1307, USA.                    --
-----------------------------------------------------------------------

with Language; use Language;
with Language.Tree.Database; use Language.Tree.Database;
with Virtual_Lists;
with Virtual_Lists.Extensive;
with Generic_Stack;
with Language.Tree; use Language.Tree;
with GNATCOLL.VFS; use GNATCOLL.VFS;
with Glib; use Glib;

--  base package of all ada semantic tree queries.

package Ada_Semantic_Tree is

   type Entity_List is private;
   --  A declaration list is an virtual list of declarations - contents
   --  partially calculated when the list is built, and partially when it's
   --  iterated over. This way, it's possible to cut the processing on too
   --  long results.

   -----------------
   -- ENTITY_VIEW --
   -----------------

   --  Declaration Analysis  --

   type Visibility_Confidence is
     (Use_Visible,
      With_Visible,
      Project_Visible,
      Public_Library_Visible,
      Not_Visible);
   --  This type is used to describe the visibility level of an entity, from a
   --  location on the file.

   type Entity_View_Record (<>) is abstract tagged private;
   type Entity_View is access all Entity_View_Record'Class;
   --  This type a view of a declaration, in a given context. It has
   --  information such as formal & actual parameters of the declaration.
   --  Instances of this type should be freed.

   Null_Entity_View : constant Entity_View;

   function Get_Construct
     (E : access Entity_View_Record'Class)
      return access Simple_Construct_Information;
   --  Return the construct designated by this declaration view.

   function Get_Category
     (E : access Entity_View_Record) return Language_Category;
   --  Return the category of the view. By default, it's the one of the
   --  construct stored but other models not based on constructs can fill
   --  that information as well.

   function To_Construct_Tree_Iterator
     (E : Entity_View) return Construct_Tree_Iterator;

   function Get_File (E : Entity_View) return Structured_File_Access;
   --  Return the file where the pointed declaration is located.

   function Is_All (E : Entity_View) return Boolean;
   --  Return true if the declaration view given in parameter is viewed trough
   --  a "all" dereference.

   procedure Set_Is_All (E : Entity_View; Is_All : Boolean);

   procedure Free (E : in out Entity_View);
   --  Free the data created for this declaration view

   function Deep_Copy (E : Entity_View) return Entity_View;
   --  Perform a deep copy of the view and its contents.

   function Get_Entity
     (E : access Entity_View_Record'Class) return Entity_Access;
   --  Return the entity pointed by this declaration view.

   function Get_Documentation
     (E : access Entity_View_Record) return UTF8_String is abstract;

   function Get_Name
     (E : access Entity_View_Record) return UTF8_String is abstract;

   type Visibility_Filter is mod 2 ** 32;

   All_Visible_Packages : constant Visibility_Filter := 2#0000_0001#;
   --  Denotes only the packages that are already in the visible scope.
   All_Visible_Entities : constant Visibility_Filter :=
     2#0000_0010# or All_Visible_Packages;
   --  Denotes all the visible entities.
   All_Accessible_Units : constant Visibility_Filter := 2#0000_0100#;
   --  Denote only the units.
   All_Types            : constant Visibility_Filter :=
     2#0000_1000# or All_Accessible_Units;
   --  Denote any expression that can be interpreted as a type designation
   --  ??? This has to be used after a 'new' or ': [in|out|access]' or 'access'
   --  token (not yet used).
   Everything           : constant Visibility_Filter := 16#FFFFFF#
     and not All_Accessible_Units;
   --  Denotes everyting.

   type Visibility_Context is record
      File                      : Structured_File_Access;
      Offset                    : Natural;
      Filter                    : Visibility_Filter := Everything;
      Min_Visibility_Confidence : Visibility_Confidence;
   end record;
   --  This type gives a way to precise the file location from which a search
   --  has to be done, with the level of precision and the kind of entities
   --  needed.

   Null_Visibility_Context : constant Visibility_Context :=
     (null, 0, 0, Not_Visible);

   procedure Fill_Children
     (E               : access Entity_View_Record;
      From_Visibility : Visibility_Context;
      Name            : String;
      Is_Partial      : Boolean;
      Result          : in out Entity_List) is null;
   --  Adds to result the children of the current entity, given the constrains
   --  in parameter.

   -----------------
   -- ENTITY_LIST --
   -----------------

   Null_Entity_List : constant Entity_List;

   type Entity_Iterator is private;
   --  This type is used to iterate over the contents of a declaration list.

   procedure Free (List : in out Entity_List);
   --  Free the data associated to a list.

   procedure Free (It : in out Entity_Iterator);
   --  Free the data associated to an iterator.

   function First (List : Entity_List) return Entity_Iterator;
   --  Return the first element found in the list.

   procedure Next (It : in out Entity_Iterator);
   --  Moves the iterator over the next declaration of the list.

   function At_End (It : Entity_Iterator) return Boolean;
   --  Return true if there is no more entities to pick up - false
   --  otherwise.

   function Is_Valid (It : Entity_Iterator) return Boolean;
   --  Return true if the iterator is in a regular state.

   function Get_View (It : Entity_Iterator) return Entity_View;
   --  Return the entity view currently pointed by the iterator. The
   --  caller is responsible for freeing the result.

   function Get_Entity (It : Entity_Iterator) return Entity_Access;
   --  Return the entity pointed by this entity iterator, if any.

   -------------------------
   -- EXCLUDED_STACK_TYPE --
   -------------------------

   type Excluded_Stack_Type is private;
   --  This type holds a stack of entities excluded by an iteration process.
   --  Entities will get pushed and poped there in order to detect circular
   --  references and avoid infinite looping.

   Null_Excluded_Stack : constant Excluded_Stack_Type;

   procedure Pop_Entity (Stack : in out Excluded_Stack_Type);
   --  Removes the last entity from the stack.

   procedure Push_Entity
     (Stack : in out Excluded_Stack_Type; Entity : Entity_Access);
   --  Add a new entity at the top of the stack.

   function Is_Excluded
     (Stack : Excluded_Stack_Type; Entity : Entity_Access) return Boolean;
   --  Return true if this entity is excluded, false otherwise. Note that this
   --  function is aware that the same entity may be spread across several
   --  declarations - exclusion will be detected even if the stored and tested
   --  entities are the same declaration part.

   procedure Ref (Stack : in out Excluded_Stack_Type);
   --  Increments the reference counter of the stack - this has to be done if
   --  the stack is stored.

   procedure Unref (Stack : in out Excluded_Stack_Type);
   --  Decrement the reference counter of the stack.

private

   type Entity_View_Record is abstract tagged record
      Entity        : Entity_Access;
      Is_All        : Boolean := False;
      From_Prefixed : Boolean := False;
      Confidence    : Visibility_Confidence;
   end record;

   procedure Free (E : in out Entity_View_Record) is null;

   procedure Deep_Copy (E : in out Entity_View_Record) is null;

   procedure Configure_View
     (E : in out Entity_View_Record; It : Entity_Iterator) is null;
   --  Extra things may have to be extracted from the iterator to the view -
   --  if so, this is the responsibility of this subprogram, called on Get_View

   Null_Entity_View : constant Entity_View := null;

   package Entity_List_Pckg is new Virtual_Lists (Entity_View);

   procedure Copy_On_Get (E : in out Entity_View);

   package Entity_List_Extensive_Pckg is new
     Entity_List_Pckg.Extensive (Copy_On_Get => Copy_On_Get);

   use Entity_List_Pckg;

   type Entity_List is record
      Contents      : Entity_List_Pckg.Virtual_List;
      Excluded_List : Excluded_Stack_Type;
   end record;

   type Entity_Iterator is record
      It            : Entity_List_Pckg.Virtual_List_Iterator;
      Excluded_List : Excluded_Stack_Type;
   end record;

   package Excluded_Stack_Pckg is new Generic_Stack (Entity_Access);

   use Excluded_Stack_Pckg;

   type Excluded_Stack_Type_Record is record
      Entities : Excluded_Stack_Pckg.Simple_Stack;
      Refs     : Integer := 0;
   end record;

   type Excluded_Stack_Type is access all Excluded_Stack_Type_Record;

   Null_Excluded_Stack : constant Excluded_Stack_Type := null;

   Null_Entity_List : constant Entity_List :=
     (Entity_List_Pckg.Null_Virtual_List, null);

end Ada_Semantic_Tree;
