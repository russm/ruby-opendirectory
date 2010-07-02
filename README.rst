ruby-opendirectory
==================

What?
-----

A simplified wrapper for MacRuby_ client applications that want to deal
with information stored in OpenDirectory_ - the goal is to make user
management easier than dealing with raw OpenDirectory.

We also wrap some management of Apple Wiki Services account preferences,
since wikid doesn't always use account info from OD and we'd like a
single centralised way of handling *all* account info.

.. _MacRuby: http://www.macruby.org/
.. _OpenDirectory: http://developer.apple.com/mac/library/documentation/Networking/Conceptual/Open_Directory/Introduction/Introduction.html


Why?
----

Because I need to manage user accounts, but the OD API makes my brain
hurt.
