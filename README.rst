vim-python-pep8-indent
======================

.. image:: https://travis-ci.org/hynek/vim-python-pep8-indent.png?branch=travis
:target: https://travis-ci.org/hynek/vim-python-pep8-indent

This small script modifies vim_’s indentation behavior to comply with PEP8_ and
my aesthetic preferences: :: python

foobar(foo,
       bar)

and :: python

foobar(
    foo,
    bar
)

It was *not* originally written by me. I have found the script in vim’s `script
repo`_, however the indentation was off by one character in the first case.

I fixed it with the help of `Steve Losh`_ and am putting it out here so you
don’t have to patch the original. The original patch is still available here_.

While my Vimscript_ skills are still feeble, I intend to maintain it for now.
So feel free to report bugs, I’ll try to address them as well as I can,
provided they fit into the scope of this project.

Unfortunately, I wasn’t able to reach any of the original authors/maintainers:
**David Bustos** and **Eric Mc Sween**. I’d like to thank them here for their
work and release it hereby to the *Public Domain*. If anyone with a say in this
objects, please let me know.

Installation
------------

Pathogen
########
Follow the instructions on installing Pathogen_ and then :: 

cd ~/.vim/bundle
git clone https://github.com/hynek/vim-python-pep8-indent.git

Vundle
######

Follow the instructions on installing Vundle_ and add the appropriate
plugin line: ::

Plugin 'hynek/vim-python-pep8-indent`

NeoBundle
#########

Follow the instructions on installing NeoBundle_ and add the appropriate
NeoBundle line: ::

NeoBundle 'hynek/vim-python-pep8-indent`

### Notes

Please note that Kirill Klenov’s [python-mode][python_mode]ships its own version
of this bundle.  Therefore, if you want to use this version specifically, 
you’ll have to disable python-mode’s using ::

let g:pymode_indent = 0

.. _vim: http://www.vim.org/
.. _PEP8: http://www.python.org/dev/peps/pep-0008/
.. _`script repo`: http://www.vim.org/scripts/script.php?script_id=974
.. _`Steve Losh`: http://stevelosh.com/
.. _here: https://gist.github.com/2965846
.. _Neobundle: https://github.com/Shougo/neobundle.vim
.. _Pathogen: https://github.com/tpope/vim-pathogen
.. _python-mode: https://github.com/klen/python-mode
.. _`Vimscript`: http://learnvimscriptthehardway.stevelosh.com/
.. _vundle: https://github.com/gmarik/Vundle.vim
