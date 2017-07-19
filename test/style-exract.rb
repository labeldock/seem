#!/usr/bin/ruby
require File.expand_path('../seem.rb', __dir__)

# Temporary TEST CODE
require "pp"
#text_1args = ["#master-header{ color:red; .common{} } #master-header{ color:blue; }",["{","}"],{nested: false}]
#puts "block matches 1 # #{text_1args}"
#pp Seem.block_matches *text_1args
#text_2inst = Seem::BlockMatches.new "#master-header{ color:red; .common{} } #master-header{ color:blue; }"
#text_2inst.blocks ["{","}"], [":",";"]
#pp text_2inst


seems = Seem.glob("*.css",__dir__).each do |seem|
    seem.block :css do |match|
        p "[1] match.content  :: #{ match.content }"
        match.block :css_name, :color do |match|
            p "[2] match.content  :: #{ match.body }"
        end
    end
end