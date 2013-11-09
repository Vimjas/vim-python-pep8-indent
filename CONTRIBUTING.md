# How To Contribute

“vim-python-pep8-indent” is always open for suggestions and contributions by generous developers. I’ve collected a few tipps to get you started.

Please:

- *Always* add tests for your code.
- Add yourself to the AUTHORS.rst file in an alphabetical fashion by first name – no matter how big or small your changes are.
- Write [good commit messages].
- Ideally, [squash] your commits, i.e. make your pull requests just one commit.

## Running Tests

- They are written in ruby (sorry :() using [vimrunner] which requires [rspec]
- The tests go into `spec/indent/indent_spec.rb`.
  Look at the `describe` blocks to get the hang of it.
- Run the tests with the command `rspec spec`

Thank you for considering to contribute!


[squash]: http://gitready.com/advanced/2009/02/10/squashing-commits-with-rebase.html
[good commit messages]: http://tbaggery.com/2008/04/19/a-note-about-git-commit-messages.html
[vimrunner]: https://github.com/AndrewRadev/vimrunner
[rspec]: https://github.com/rspec/rspec
