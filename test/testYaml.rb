

require 'yaml'


def report(yaml, lv = 0)
	indent = "\t" * lv
	lines = []
	yaml.each {|k,v| lines << "#{reportThing(k,'K>',lv)}" << "#{reportThing(v,'=>',lv)}" }
	lines.join("\n")
end

def reportThing(obj, head, lv = 0)
	ptext = case obj
		when Hash
			report(obj,lv+1)
		when Array
			xobjs = obj.map {|xobj| reportThing(xobj,'- ',lv+1)}
			"A[\n#{xobjs.join("\n")}\n#{"\t" * lv}]"
		else
			"#{obj.to_s}::#{obj.class}"
	end

	"#{"\t"* lv}#{head} #{ptext}\n"
end

yaml = YAML.load_file('./test/blah.yaml')
puts yaml.class
puts yaml
puts report(yaml)








