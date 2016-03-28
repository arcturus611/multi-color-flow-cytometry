classdef mySingleton < handle
   %SINGLETON Abstract Class for Singleton OOP Design Pattern
   %  Intent:  Ensures a class only has one instance and provide a
   %  global point of access to it.
   %  Motivation:  It's important for some classes to have exactly one
   %  instance.  For example, it can be desirable to have only a
   %  single instance of a GUI.  With a MATLAB GUIDE built GUI, the driver
   %  or main function provides a global point of access which is
   %  executed to,
   %  1. initially instantiate the GUI; and
   %  2. subsequently bring the existing GUI into focus *not* creating
   %     a new one.
   %  Implementation:  MATLAB OOP doesn't have the notion of static
   %  properties.  Properties become available once the constructor
   %  of the class is invoked.  In the case of the Singleton Pattern, it
   %  is then undesirable to use the constructor as a global point of
   %  access since it creates a new instance before you can check if an
   %  instance already exists.  The solution is to use a persistent
   %  variable within a unique static method instance() which calls the
   %  constructor to create a unique 'singleton' instance.  The persistent
   %  variable can be interrogated prior to object creation and after
   %  object creation to check if the singleton object exists.  There are
   %  two conditions that all subclasses must satisfy:
   %  1. Constructor must be hidden from the user (Access=private).
   %  2. The concrete implementation of instance() must use a persistent
   %     variable to store the unique instance of the subclass.


   methods(Abstract, Static)
      % This method serves as the global point of access in creating a
      % single instance *or* acquiring a reference to the singleton.
      % If the object doesn't exist, create it otherwise return the
      % existing one in persistent memory.
      % Input:
      %    <none>
      % Output:
      %    obj = reference to a persistent instance of the class
      obj = instance();
   end   
end
