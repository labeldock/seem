#!/usr/bin/ruby
module Seem
    
    BLOCK_PRESETS = {
        css: Proc.new { |name=nil|
            [/[\w+\s^\n\}]\{/,'}']
        },
        css_name: Proc.new { |name=nil|
            [":",';']
        }
    }
    
    def self.block_presets *args
        preset = BLOCK_PRESETS[args[0]]
        if preset
            preset.call
        else
            args[0]
        end
    end
    
    def self.block_matches text, exp, opt=nil
        
        meta = opt.class == Hash ? opt : {}
        meta[:from]      = 0 unless meta[:from].class   == Integer
        meta[:depth]     = 0 unless meta[:depth].class  == Integer
        meta[:offset]    = 0 unless meta[:offset].class == Integer
        meta[:nested]    = false unless meta[:nested] == true or meta[:nested] == false
        meta[:reference] = meta[:reference].class == Seem::Area ? meta[:reference] : nil
        
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
    
    class BlockMatch
        attr_reader :reference, :matches
        
        def initialize opts={}
            opts  = opts.class == Hash ? opts : {}
            
            @reference = opts[:reference]  || nil
            @match     = {
                head:       opts[:head]       || '',
                body:       opts[:body]       || '' ,
                foot:       opts[:foot]       || '',
                depth:      opts[:depth]      || nil,
                begin:      opts[:begin]      || nil,
                end:        opts[:end]        || nil,
                body_begin: opts[:body_begin] || nil,
                body_end:   opts[:body_end]   || nil
            }
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
            @match[:head] + @match[:body] + @match[:foot]
        end
        def block *block_exps
            matches = Seem::block_matches @match[:body], Seem::block_presets(*block_exps), {reference: @reference, offset: @match[:begin]}
            matches.each{ |block_match| yield block_match } if block_given?
            matches
        end
        def replace
            return unless @reference
        end
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
            @que  = []
        end
        
        def block *block_exps
            matches = Seem::block_matches @text, Seem::block_presets(*block_exps), {reference: self}
            matches.each{ |block_match| yield block_match } if block_given?
            matches
        end
        
        def clone
            self.class.new(@text, @path)
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
            @texts.each do |seem_area|
                yield seem_area
            end
        end
        
        def clone
            files_clone = self.class.new
            files_clone.texts = @texts.map do |seem_area|
                seem_area.clone
            end
            files_clone
        end
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