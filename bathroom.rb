#!/usr/bin/env ruby
# encoding: utf-8
TOILET_PATH = `which toilet`.strip
class String
  def basename(strip_extension=true)
    name = File.basename(self)
    name.gsub!(/\..+?$/,'') if strip_extension
    name
  end
end

class Toilets
  attr_accessor :deleted_fonts, :not_deleted_fonts, :fonts_dir, :fonts_mask, 
  :sample_text, :extra_toilet_options, :selected_font,
  :filters, :colour_filter, :output_format, :width, :use_sudo_for_delete

  def initialize(fonts_dir=nil)
    @fonts_dir = fonts_dir
    @fonts_mask = '*.?lf'
    @deleted_fonts = []
    @not_deleted_fonts = []
    @output_format = nil
    @extra_toilet_options = []
    @use_sudo_for_delete = false
  end

  def supported_output_format_pairs
    `toilet -E list`.split("\n").map{|line|md = line.match(/\"(.+)\": (.+)/); md ? [md[1],md[2]] : nil}.compact
  end

  def supported_output_formats 
    supported_output_format_pairs.map{|k,v|k}
  end

  def supported_filter_pairs
    `toilet -F list`.split("\n").map{|line|md = line.match(/\"(.+)\": (.+)/); md ? [md[1],md[2]] : nil}.compact
  end

  def supported_filters
    supported_filter_pairs.map{|k,v|k}
  end

  def supported_fonts
    fonts.map{|path,name|name}.sort.uniq
  end

  def selected_filters
    [colour_filter,filters].compact.uniq
  end

  def toilet_options
    str = ''
    str += " -d \"#{sanitised_fonts_dir}\"" if fonts_dir.to_s.size > 0
    str += " -F #{selected_filters.join(':')}" if selected_filters.size > 0
    str += " -E #{output_format}" if output_format
    str += " -f #{selected_font}" if selected_font && supported_fonts.include?(selected_font)
    str += " -t" if width == :auto
    str += " -w #{width}" if width.to_i > 0
    str += " #{extra_toilet_options.uniq.join(' ')}" if extra_toilet_options.size > 0
    str
  end

  def command(text=nil)
    return "#{TOILET_PATH}#{toilet_options}" if text.nil?
    "#{TOILET_PATH}#{toilet_options} \"#{text}\""
  end

  def text_command(text=nil)
    text = sample_text if text.to_s.empty?
    "#{TOILET_PATH}#{toilet_options} \"#{text}\""
  end

  def run_command(text=nil)
    `#{command(text)}`
  end

  def run_text_command(text=nil)
    `#{text_command(text)}`
  end

  # Clear all settings
  def flush

  end

  def colour_filter=(format_type)
    case format_type.to_s
    when 'rainbow', 'gay'
      @colour_filter = 'gay'
    when 'metal'
      @colour_filter = 'metal'
    else
      @colour_filter = nil
    end
  end

  def rainbow
    self.colour_filter = 'rainbow'
  end

  def metal
    self.colour_filter = 'metal'
  end

  def width=(chars)
    if chars == :auto
      @width = chars
    elsif chars.to_i > 0
      @width = chars.to_i
    else
      puts "#{chars} is not a valid width. Please use :auto, or a valid integer"
      @width = nil
    end
  end

  def output_format=(format_type)
    return @output_format = format_type if supported_output_formats.include?(format_type)
    puts "'#{format_type}' is an invalid output format. Please supply one of: #{supported_output_formats.join(', ')}"
    false
  end

  def sanitised_fonts_dir
    return '/usr/share/figlet/' if fonts_dir.nil? || !File.exist?(fonts_dir)
    fonts_dir
  end

  def fonts
    file_path = File.join(sanitised_fonts_dir.to_s,fonts_mask)
    Dir.glob(file_path).sort.map{|filepath|[filepath,filepath.basename(true)]}
  end

  def user_input(message=nil)
    ARGV.clear #clear ARGV so gets doesn't try to read the arguments first.
    puts message if message
    gets.chomp
  end

  def delete_font?
    delete = user_input("Want to delete this font? (y/N/abort)")
    return abort(report) if delete == 'abort'
    if ['n','no', ''].include?(delete.downcase)
      return false
    elsif ['y','yes'].include?(delete.downcase)
      return true
    else
      puts "Sorry, '#{delete}' isn't an allowed answer."
      delete_font?
    end
  end

  def delete_font(filepath, font_name=nil)
    puts "Deleting font #{font_name||filepath.basename(true)}"
    cmd = 'rm -f "%s"' % filepath
    cmd = 'sudo %s' % cmd if use_sudo_for_delete
    
    puts cmd 
    puts `#{cmd}`
    if $?.success?
      @deleted_fonts << filepath
      puts "Deleted #{filepath}"
    else
      puts "Could not delete #{filepath}"
      @not_deleted_fonts << filepath
    end
    puts 
  end

  def sample_text
    @sample_text||@selected_font||"abc def ghi jkl mno pqr stu vwx yz"
  end

  def list_fonts_with_examples(range=0..-1)
    fonts[range].each do |font_path, font_name|
      begin
        @selected_font = font_name
        puts text_command(sample_text)
        puts run_text_command(sample_text)
        yield(font_path, font_name) if block_given?
        puts "#{font_name}"
        puts '-' * 80
        puts
      rescue StandardError => e
        puts "Error #{e.class.name} while listing fonts:"
        p e
        puts e.backtrace
        next
      end
    end
    @selected_font = nil
  end

  def list_fonts_with_delete_option
    list_fonts_with_examples do |font_path, font_name|
      begin
        delete_font(font_path, font_name) if delete_font?
      rescue StandardError => e
        puts "Error #{e.class.name} while trying to delete file"
        p e
        puts e.backtrace
      end
    end
  ensure
    report
  end 

  def report
    #TODO: clean this up with a heredoc
    str = "The following #{@deleted_fonts.size} fonts were deleted: \n"
    str += @deleted_fonts.join("\n") + "\n"
    str += "\n"

    str += "The following #{@not_deleted_fonts.size} fonts could not be deleted: \n"
    str += @not_deleted_fonts.join("\n") + "\n"
    str += "\n"

    str += "You can use the following commands to delete them all manually:\n"
    @not_deleted_fonts.each do |filepath|
      str += "rm #{filepath}" + "\n"
    end
    str += "\n"

    str += "Or if you need to sudo:\n"
    @not_deleted_fonts.each do |filepath|
      str += "sudo rm #{filepath}" + "\n"
    end
    str += "\n"
  end

  def report_supported_fonts
    puts "Supported Fonts:"
    puts supported_fonts.join(', ')
    puts
  end

  def report_supported_output_formats
    puts "Supported Formats:"
    puts supported_output_format_pairs.map{|pair|pair.join(': ')}.join("\n")
    puts
  end

  def report_supported_filters
    puts "Supported Filters:"
    puts supported_filter_pairs.map{|pair|pair.join(': ')}.join("\n")
    puts
  end

  def support_report
    report_supported_fonts
    report_supported_output_formats
    report_supported_filters
  end

  def random_font
    supported_fonts.sample
  end

  def print_verbose_text
    puts text_command
    puts run_text_command
    puts selected_font
  end
end


t = Toilets.new
arguments = ARGV.dup
t.output_format = 'irc' if arguments.include?('--irc')
t.output_format = 'html' if arguments.include?('--html')
t.output_format = 'utf8cr' if arguments.include?('--unicode-cr')
t.output_format = 'utf8' if arguments.include?('--unicode')
t.output_format = 'ansi' if arguments.include?('--ansi')
t.output_format = 'caca' if arguments.include?('--caca')
t.metal if arguments.include?('--metal')
t.rainbow  if arguments.include?('--gay') || arguments.include?('--rainbow')

if arguments.include?('--usage') || arguments.include?('--help') || arguments.include?('--?')
  puts "A couple of usage examples:"
  puts '-' * 80
  puts "Print 'Hello world!' in rainbow colours with IRC formatting using a random font"
  puts "  #{__FILE__} --irc --random-font --text 'Hello world!' --rainbow --output"
  puts 
  puts "Print the font name in metallic colours with unicode formatting using the calgphy2 font"
  puts "  #{__FILE__} --unicode --metal --font calgphy2 --output"
  puts 
  puts "List all fonts installed in /path/to/your/figlet/fontsdir"
  puts "  #{__FILE__} --fonts-dir /path/to/your/figlet/fontsdir --fonts"
  puts 
  puts "List all installed fonts, supported filters and formats based on default fonts-dir of /usr/share/figlet/"
  puts "  #{__FILE__} --support"
  puts 
  puts "List all supported filters and formats:"
  puts "  #{__FILE__} --filters --formats"
  puts
  puts "For each installed font, output the toilet command and the font name, along with the alphabet showcasing each font."
  puts "  #{__FILE__} --output-all --text-alphabet"
  puts
  puts "Ask for each font if you want to delete the font or keep it."
  puts "  #{__FILE__} --interactive-delete"
  puts
end

if index = (arguments.index('--format')||arguments.index('-E'))
  if arguments.size > index
    if t.supported_output_formats.include?(arguments[index+1])
      t.output_format = arguments[index+1]
    else
      puts "Could not find output format '#{arguments[index+1]}'. Please supply one of #{t.supported_output_formats.join(', ')}."
    end
  else
    puts "Please supply an output format after the '#{arguments[index]}' argument."
  end
end

if index = (arguments.index('--fonts-dir')||arguments.index('-f'))
  if arguments.size > index
    path = File.expand_path(arguments[index+1].to_s)
    if File.directory?(path)
      t.fonts_dir = path
    else
      puts "'#{arguments[index+1]}' is not an existing directory."
    end
  else
    puts "Please supply a fonts-dir after the '#{arguments[index]}' argument."
  end
end

t.selected_font = t.random_font if arguments.include?('--random-font')
if index = (arguments.index('--font')||arguments.index('-f'))
  if arguments.size > index
    if t.supported_fonts.include?(arguments[index+1])
      t.selected_font = arguments[index+1]
    else
      puts "Could not find font '#{arguments[index+1]}'. Please supply one of #{t.supported_fonts.join(', ')}."
    end
  else
    puts "Please supply a font after the '#{arguments[index]}' argument."
  end
end

if index = (arguments.index('--text')||arguments.index('-t'))
  if arguments.size > index
    t.sample_text = arguments[index+1]
  else
    puts "Please supply a sample text after the '#{arguments[index]}' argument. Defaulting to '#{t.sample_text}'"
  end
end
t.sample_text = ('a'..'z').to_a.join('') if arguments.include?('--text-alphabet')
t.sample_text = ('A'..'Z').to_a.join('') if arguments.include?('--text-alphabet-upcase')

if arguments.include?('--term-width') || arguments.include?('--t')
  t.width = :auto 
elsif index = (arguments.index('--width')||arguments.index('-w'))
  if arguments.size > index
    t.width = arguments[index+1].to_i
  else
    puts "Please supply a output width after the '#{arguments[index]}' argument."
  end
end

t.support_report if arguments.include?('--support')
t.report_supported_fonts if arguments.include?('--fonts')
t.report_supported_output_formats if arguments.include?('--formats')
t.report_supported_filters if arguments.include?('--filters')

if index = arguments.index('--toilet-options')
  if arguments.size > index
    t.extra_toilet_options << arguments[index+1]
  else
    puts "Please supply your toilet options as a single argument between double quotes after the '#{arguments[index]}' argument."
  end
end

if arguments.include?('--interactive-delete')
  t.use_sudo_for_delete = true if arguments.include?('--use-sudo')
  puts t.use_sudo_for_delete
  puts t.list_fonts_with_delete_option
end


if arguments.include?('--output') || arguments.include?('--print')
  if arguments.include?('--with-names')
    t.print_verbose_text
  else
    puts t.run_text_command
  end
end

if arguments.include?('--output-all') || arguments.include?('--print-all')
  t.list_fonts_with_examples
end
