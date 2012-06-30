vim-python-pep8-indent
======================

This small script modifies vim_’s indentation behavior to comply with PEP8_ and
my aesthetic preferences: ::

   foobar(foo,
          bar)

and ::

   foobar(
      foo,
      bar
   )

It was *not* originally written by me. I have found the script in vim’s `script
repo`_, however the indentation was off by one character in the first case.

I fixed it with the help of `Steve Losh`_ and am putting it out here so you
don’t have to patch the original. The original patch is still available here_.

While my Vimscript_ skills are still feeble, I intend to maintain it for now.
So feel free to report bugs, I’ll try to address them as good as possible if
they fit into the scope of this project.

Unfortunately, I wasn’t able to reach any of the original authors/maintainers:
**David Bustos** and **Eric Mc Sween**. I’d like to thank them here for their
work and release it hereby to the *Public Domain*. If anyone – who has a say in
this – objects, please let me know.

Installation
------------

The easiest way is to use pathogen_ and do a ::

   git clone https://github.com/hynek/vim-python-pep8-indent.git

in your `~/.vim/bundle`. And you *should* use pathogen. Really.

.. _vim: http://www.vim.org/
.. _PEP8: http://www.python.org/dev/peps/pep-0008/
.. _`script repo`: http://www.vim.org/scripts/script.php?script_id=974
.. _`Steve Losh`: http://stevelosh.com/
.. _here: https://gist.github.com/2965846
.. _`Vimscript`: http://learnvimscriptthehardway.stevelosh.com/
.. _pathogen: https://github.com/tpope/vim-pathogen
