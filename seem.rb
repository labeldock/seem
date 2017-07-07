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
        
        def match_select exp *exps
            
        end
        
        def clone
            files_clone = self.class.new
            files_clone.texts = @texts.map do |seem_text|
                seem_text.clone
            end
            files_clone
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
    
    def self.StyleBlock
        [/[\w+\s^\n\}]\{/,'}']
    end
    
    private
    
    def self.to_a data
        data.class == Array ? data : [data]
    end
end