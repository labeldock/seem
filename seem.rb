#!/usr/bin/ruby
module Seem
    
    class Text
        attr_reader :text, :path
        
        def self.read path
            init_result = nil
            File.open(path,'r') do |file|
                init_result = self.new(file.read,path)
            end
            init_result
        end
 
        def initialize text="", path=nil
            @text = text
            @path = path
        end
        
        def clone
            self.class.new(@text, @path)
        end
        
        def pathExsist?
            
        end
    end
    
    class Files
        attr_accessor :texts
        
        def initialize pathes=[]
            pathes = Seem::to_a(pathes)
            @texts = pathes.map do |path|
                Seem::Text.read(path)
            end
        end
        
        def each_replace exp, *iexps
            exps = (iexps == nil ? [] : (iexps.class == Array ? iexps : [iexps])).reverse
            
            @texts.each do |seem_text|
                seem_text.text.match()
            end
        end
        
        def clone
            files_clone = self.class.new
            files_clone.texts = @texts.map do |seem_text|
                seem_text.clone
            end
            files_clone
        end
    end
    
    class BlockMatch
        attr_reader :reference, :match
        
        def initialize opts={}
            @match  = {}
            
            opts = opts.class == Hash ? opts : {}
            
            @reference,
            @match[:head],       @match[:body],    @match[:foot],
            @match[:depth],      @match[:begin],   @match[:end],
            @match[:body_begin], @match[:body_end] = 
            opts[:reference]  || nil, 
            opts[:head]       || '',  opts[:body]     || '' , opts[:foot] || '',
            opts[:depth]      || nil, opts[:begin]    || nil, opts[:end] || nil,
            opts[:body_begin] || nil, opts[:body_end] || nil
        end
        def head
            @match[:head]
        end
        def body
            @match[:body]
        end
        def foot
            @match[:foot]
        end
        def content
            self.head + self.body + self.foot
        end
    end
    
    @@base_path = Dir.pwd
    
    def self.read  path, charset=nil
        self::Text.read(path, charset=nil)
    end
    
    def self.glob (pathes, base_path=@@base_path)
        glob_pathes = []
        
        Seem::to_a(pathes).each do |path|
            expand_path = File.expand_path(path,base_path);
            expand_glob = Dir.glob(expand_path)
            glob_pathes = glob_pathes + expand_glob if expand_glob.any?
        end
        
        self::Files.new(glob_pathes)
    end
    
    def self._style_block
        [/[\w+\s^\n\}]\{/,'}']
    end
    
    def self._style attr=nil
        []
    end
    
    def self.block_matches text, exp, from=0, depth=0, inner_matches=true
        if (exp.class != Array) || (exp.length < 2)
            raise "Worong block expression #{exp}"
            return nil
        end
        
        block_matches = []
        
        opener_exp = exp[0].class == String ? Regexp.escape(exp[0]) : exp[0]
        closer_exp = exp[1].class == String ? Regexp.escape(exp[1]) : exp[1]
        
        # scope start index
        match_head = text.match opener_exp, from
        
        # when not found block head
        return block_matches unless match_head
        
        # when block head exsist
        mhead_begin_index = match_head.begin 0
        mhead_end_index   = match_head.end 0
        
        # find foot index
        match_foot = text.match closer_exp, mhead_end_index  
        
        # when not found block end
        return block_matches unless match_foot
        
        # when block end exsist
        mfoot_begin_index = match_foot.begin 0
        mfoot_end_index   = match_foot.end   0
        
        
        # find next heading index
        match_next_opener       = text.match opener_exp, mhead_end_index
        next_opener_begin_index = match_next_opener && match_next_opener.begin(0)
        next_opener_end_index   = match_next_opener && match_next_opener.end(0)
        
        # init tracking variant
        opener_track_index  = mhead_end_index
        closer_track_index  = mfoot_end_index
        track_depth  = 0
        
        puts "begin , #{from}"
        begin
            if !next_opener_begin_index && mfoot_begin_index
                # next opener not exsist
                puts "raise:PERMIT 1"
                raise Seem::Raise.new :PERMIT
            elsif (next_opener_begin_index > mfoot_begin_index) && (track_depth == 0)
                # next opener is far away
                puts "raise:PERMIT 2"
                raise Seem::Raise.new :PERMIT
            elsif next_opener_begin_index < mfoot_begin_index
                # next opener exsist
                puts ":NEXT_OPENERraise_EXSIST"
                raise Seem::Raise.new :NEXT_OPENER_EXSIST
            else
                # exit
                puts "raise:EXIT"
                raise Seem::Reason.new :EXIT
            end
        rescue Seem::Raise => seem_raise
            case seem_raise.reason
            when :PERMIT
                # process finally
                block_matches << Seem::BlockMatch.new({
                    reference:text,
                    head: text[mhead_begin_index ... mhead_end_index],
                    body: text[mhead_end_index   ... mfoot_begin_index],
                    foot: text[mfoot_begin_index ... mfoot_end_index],
                    depth: depth,
                    begin: mhead_begin_index,
                    end: mfoot_end_index,
                    body_begin:mhead_end_index,
                    body_end:mfoot_begin_index,
                })
                
                next_matches = self.block_matches(text, exp, mfoot_end_index);
                block_matches << next_matches unless next_matches.empty?
            when :EXIT
                puts "exit"
            when :NEXT_OPENER_EXSIST
                puts ":NEXT_OPENER_EXSIST"
            else
                print seem_raise
            end
        rescue
            puts "Something went wrong => #{reason}"
        end
        
        return block_matches
    end
    
    class Raise < StandardError
        attr_accessor :reason
        def initialize reason
            @reason = reason
        end
    end
    
    private
    
    def self.to_a data
        data.class == Array ? data : [data]
    end
end



# Temporary TEST CODE

require "pp"
text_1args   = "#master-header{ color:red; } #master-header{ color:blue; }",["{","}"]

puts "block matches 1 # #{text_1args}"
pp Seem.block_matches *text_1args
