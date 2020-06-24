# How-to - Write a basic Cookstyle Rule

This guide will provide a basic introduction to writing and installing custom Cookstyle rules.

## Before You Start

### Assumptions

* Chef Workstation with Cookstyle installed
* Familiarity with Ruby
* Install ruby-parse utility: `gem install parser`

### Tested Versions

* Chef Workstation
* Cookstyle
* Chef Infra

## The Basics of Creating a Cookstyle test.

### The Basic Format
```
module RuboCop
 module Cop
   module Chef
     module ${Cop Type}
       # Cookbook:: This is the cop’s purpose.
       #
       # @example
       #
       #   # bad
       #   ${bad example code}
       #
       #   # good
       #   ${good example code}
       #
       class ${Cop Name} < Cop
         MSG = 'This will be displayed on violation'.freeze
 
         def_node_matcher :search_method?, <<-PATTERN
           ${AST Pattern Here}
         PATTERN
 
         def on_send(node)
           search_method?(node) do |check|
             add_offense(node, location: :expression, message: MSG, severity: :refactor) unless check condition
           end
         end
 
         def autocorrect(node)
           lambda do |corrector|
             new_val = 'new value'
             corrector.replace(node.loc.expression, new_val)
           end
         end
       end
     end
   end
 end
end
```

### Node Matcher and AST
Abstract Syntax Tree (AST) allows you to crawl trees of text, and the Rubocop documentation gives a good overview. It’s a good idea to read the following document from them, as it will give you a decent look at Cookstyle:
https://rubocop.readthedocs.io/en/latest/development/

#### Ruby Parse
```
$ ruby-parse -h
Usage: ruby-parse [options] FILE|DIRECTORY...
        --18                         Parse as Ruby 1.8.7 would
        --19                         Parse as Ruby 1.9.3 would
        --20                         Parse as Ruby 2.0 would
        --21                         Parse as Ruby 2.1 would
        --22                         Parse as Ruby 2.2 would
        --23                         Parse as Ruby 2.3 would
        --24                         Parse as Ruby 2.4 would
        --25                         Parse as Ruby 2.5 would
        --26                         Parse as Ruby 2.6 would
        --27                         Parse as Ruby 2.7 would
        --28                         Parse as Ruby 2.8 would
        --mac                        Parse as MacRuby 0.12 would
        --ios                        Parse as mid-2015 RubyMotion would
    -w, --warnings                   Enable warnings
    -B, --benchmark                  Benchmark the processor
    -e fragment                      Process a fragment of Ruby code
    -L, --locate                     Explain how source maps for AST nodes are laid out
    -E, --explain                    Explain how the source is tokenized
        --emit-ruby                  Emit S-expressions as valid Ruby code
        --emit-json                  Emit S-expressions as valid JSON
    -h, --help                       Display this help message and exit
    -V, --version                    Output version information and exit
```
Here's an example of how the parser looks in action:
```
ruby-parse -e "bad example text here"
(send nil :bad
  (send nil :example
    (send nil :text
      (send nil :here))))
```
However, if we want to look at a step through of each selector in that example to understand the selection better, we will want to use -LE:
```
$ ruby-parse -LEe "bad example text here"
bad example text here   
^~~ tIDENTIFIER "bad"                           expr_cmdarg  [0 <= cond] [0 <= cmdarg] 
bad example text here   
    ^~~~~~~ tIDENTIFIER "example"               expr_arg     [0 <= cond] [0 <= cmdarg] 
bad example text here   
            ^~~~ tIDENTIFIER "text"             expr_arg     [0 <= cond] [1 <= cmdarg] 
bad example text here   
                 ^~~~ tIDENTIFIER "here"        expr_arg     [0 <= cond] [11 <= cmdarg] 
bad example text here   
                     ^ false "$eof"             expr_arg     [0 <= cond] [111 <= cmdarg] 
s(:send, nil, :bad,
  s(:send, nil, :example,
    s(:send, nil, :text,
      s(:send, nil, :here))))
bad example text here
~~~ selector                    
~~~~~~~~~~~~~~~~~~~~~ expression
s(:send, nil, :example,
  s(:send, nil, :text,
    s(:send, nil, :here)))
bad example text here
    ~~~~~~~ selector            
    ~~~~~~~~~~~~~~~~~ expression
s(:send, nil, :text,
  s(:send, nil, :here))
bad example text here
            ~~~~ selector       
            ~~~~~~~~~ expression
s(:send, nil, :here)
bad example text here
                 ~~~~ selector  
                 ~~~~ expression
```
## FAQs
1. How do I return the matched text, or a portion of it, for testing specific values?<br />
$ combined with a matcher will return that match. This will allow partial matches on a value. ‘…’ will return an array, while ‘_’ will return a string.
2. The matches aren't returning as expected using the generated AST. What's wrong?<br /> 
Use `send nil?` instead of `send nil`.<br /> 
Examples: $... will return an array of matches, $_ will return a string.