#!/usr/bin/ruby
module Seem
    
    class BlockMatch
        attr_reader :reference, :matches
        
        def initialize opts={}
            opts  = opts.class == Hash ? opts : {}
            
            @reference = opts[:reference]  || nil
            @matches = [{
                head:       opts[:head]       || '',
                body:       opts[:body]       || '' ,
                foot:       opts[:foot]       || '',
                depth:      opts[:depth]      || nil,
                begin:      opts[:begin]      || nil,
                end:        opts[:end]        || nil,
                body_begin: opts[:body_begin] || nil,
                body_end:   opts[:body_end]   || nil
            }]
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
        def matched
            @matches.last
        end
        def content
            last = self.matched
            last and (last[:head] + last[:body] + last[:foot])
        end
    end
    
    def self.block_matches text, exp, opt=nil
        
        meta = opt.class == Hash ? opt : {}
        meta[:from]      = 0 unless meta[:from].class   == Integer
        meta[:depth]     = 0 unless meta[:depth].class  == Integer
        meta[:offset]    = 0 unless meta[:offset].class == Integer
        meta[:nested]    = false unless meta[:nested] == true or meta[:nested] == false
        meta[:reference] ||= text
        
        if (exp.class != Array) || (exp.length < 2)
            raise "Worong block expression #{exp}"
            return nil
        end
        
        # result
        block_matches = []
        
        #expression
        opener, closer = 
        exp[0].class == String ? Regexp.escape(exp[0]) : exp[0],
        exp[1].class == String ? Regexp.escape(exp[1]) : exp[1];
        
        #helper
        text_match_from = lambda do |match_expression, from_start_index|
            # find match
            match = text.match match_expression, from_start_index
            match and { match: match, begin: match.begin(0), end: match.end(0) }
        end
        
        # master_header
        master_header = text_match_from.call opener, meta[:from]
        return block_matches unless master_header
        
        # master_footer
        master_footer = text_match_from.call closer, master_header[:end]
        return block_matches unless master_footer
        
        # track : next header, current footer
        track_header = text_match_from.call opener, master_header[:end]
        track_footer = master_footer
        
        # track currect
        track_currected = true
        if track_header and (track_header[:end] < master_footer[:end])
            #block incoorrect ... need recalibrated
            track_currected  = false
            track_calibrated = false
            
            begin
                track_footer = text_match_from.call closer, track_footer[:end]
                track_header = text_match_from.call opener, track_header[:end]
                
                if track_footer == nil
                    track_currected, track_calibrated = false, true
                elsif track_header == nil or (track_header[:end] > track_footer[:end])
                    master_footer, track_currected, track_calibrated = track_footer, true, true
                end
                
            end while track_calibrated != true
        end 
        
        if track_currected
            
            body_content = text[master_header[:end] ... master_footer[:begin]];
            hash_result  = {
                reference:  meta[:reference],
                head:       text[master_header[:begin] ... master_header[:end]],
                body:       body_content,
                foot:       text[master_footer[:begin] ... master_footer[:end]],
                depth:      meta[:depth],
                begin:      meta[:offset] + master_header[:begin],
                end:        meta[:offset] + master_footer[:end],
                body_begin: meta[:offset] + master_header[:end],
                body_end:   meta[:offset] + master_footer[:begin],
            }
            
            block_matches << (meta[:plain] ? hash_result : Seem::BlockMatch.new(hash_result))
            
            # find child
            if meta[:nested]
                sub_opts = meta.clone
                sub_opts[:depth]     = meta[:depth] + 1
                sub_opts[:offset]    = meta[:offset] + master_header[:end]
                sub_opts[:reference] = meta[:reference] || text
                
                sub_matches = self.block_matches(body_content,exp,sub_opts)
                
                #offset
                if(meta[:depth] == 0)
                    sub_matches
                end
                
                block_matches.concat sub_matches unless sub_matches.empty?
            end
            
            # find next
            next_matches = self.block_matches(text, exp, {from: master_footer[:end]});
            block_matches.concat next_matches unless next_matches.empty?
        end
        
        return block_matches
    end
    
    
    class BlockMatches < Array
        attr_reader :reference, :history
        
        def initialize text
            @reference = text
            @history = []
        end
        
        def setup! block_exp
            self.clear
            @history = [block_exp] unless @history.empty?
            self.concat Seem::block_matches(@reference, block_exp)
            return self
        end
        
        def setup block_exp
            self.setup!(block_exp) if Seem::block_expression? block_exp
            return self
        end
        
        def block block_exp
            if Seem::block_expression? block_exp
                if @history.length == 0
                    self.setup! block_exp
                else
                    modify_maches = []
                    self.each do |block_match|
                        modify_maches.concat block_match.modify
                    end
                    self.clear
                    self.concat modify_maches
                end
            else
                raise StandardError.new "Seem::BlockMatches.block argument is worng #{block_exp}"
            end
            return self
        end
        
        def blocks *block_exps
            block_exps.each do |block_exp|
                self.block block_exp
            end
        end
    end
    
    
    def self.read  path, charset=nil
        Seem::Area.read(path, charset=nil)
    end
    
    def self.glob (pathes, base_path=Dir.pwd)
        glob_pathes = []
        
        Seem::to_a(pathes).each do |path|
            expand_path = File.expand_path(path,base_path);
            expand_glob = Dir.glob(expand_path)
            glob_pathes = glob_pathes + expand_glob if expand_glob.any?
        end
        
        Seem::Files.new(glob_pathes)
    end
    
    class Area
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
                Seem::Area.read(path)
            end
        end
        
        def each
            @texts.each do |seem_text|
                yield seem_text
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
    
    def self.STYLE_BLOCK
        [/[\w+\s^\n\}]\{/,'}']
    end
    
    def self.STYLE_NAME name
        [Regexp.new("#{name}\:"),";"]
    end
    
    private
    
    def self.block_expression? block_exp
        block_exp.class == Array and 
        block_exp.length > 1     and
        block_exp.all? { |exp|
            exp.instance_of? Regexp or
            exp.instance_of? String
        }
    end
    
    def self.to_a data
        data.class == Array ? data : [data]
    end
end