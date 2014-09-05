## vim-python-pep8-indent                                                          

<a href="https://travis-ci.org/hynek/vim-python-pep8-indent">                      
    <img src=https://travis-ci.org/hynek/vim-python-pep8-indent.png?branch=travis />
</a>                                                                               


This small script modifies [vim][vim]’s indentation behavior to comply with [PEP8][pep8] and 
my aesthetic preferences:                                                          

```python                                                                          
foobar(foo,                           
       bar)                                                                        
```                                                                                

and                                                                                

```python                                                                          
foobar(                                                                            
    foo,                                                                           
    bar                                                                            
)                                                                                  
```                                                                                

It was *not* originally written by me. I have found the script in vim’s [script 
repo][script_repo], however the indentation was off by one character in the first case.

I fixed it with the help of [Steve Losh][steve_losh] and am putting it out here so you 
don’t have to patch the original. The original patch is still available [here][patch].

While my [Vimscript][vimscript] skills are still feeble, I intend to maintain it for now.
So feel free to report bugs, I’ll try to address them as well as I can, provided
they fit into the scope of this project.                                           

Unfortunately, I wasn’t able to reach any of the original authors/maintainers:  
**David Bustos** and **Eric Mc Sween**. I’d like to thank them here for their   
work and release it hereby to the *Public Domain*. If anyone with a say in this 
objects, please let me know.                                                       

### Installation                                                                   

#### Pathogen                                                                      
cd to `~/.vim/bundle` and                                                          
```                                                                                
git clone https://github.com/hynek/vim-python-pep8-indent.git                      
```                                                                                

#### Vundle                                                                        

Follow the instructions on installing [Vundle][vundle] and add the appropriate  
plugin line:                                                                       

```                                                                                
Plugin 'hynek/vim-python-pep8-indent`                                              
```                                                                                

#### NeoBundle                                                                     

Follow the instructions on installing [NeoBundle][neobundle] and add the appropriate
NeoBundle line:                                                                    

```                                                                                
NeoBundle 'hynek/vim-python-pep8-indent`                                           
```                                                                                

### Notes                                                                          

Please note that Kirill Klenov’s [python-mode][python_mode]ships an own version of this bundle.
Therefore, if you want to use this version specifically, you’ll have to disable python-mode’s using

```                                                                                
let g:pymode_indent = 0                                                            
```                                                                                

[vim]: http://www.vim.org/                                                         
[pep8]: http://www.python.org/dev/peps/pep-0008/                                   
[script_repo]: http://www.vim.org/scripts/script.php?script_id=974                 
[steve_losh]: http://stevelosh.com/                                                
[patch]: https://gist.github.com/2965846                                           
[vimscript]: http://learnvimscriptthehardway.stevelosh.com/                        
[pathogen]: https://github.com/tpope/vim-pathogen                                  
[python_mode]: https://github.com/klen/python-mode                                 
[vundle]: https://github.com/gmarik/Vundle.vim
