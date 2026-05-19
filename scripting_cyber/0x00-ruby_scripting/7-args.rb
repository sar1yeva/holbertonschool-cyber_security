def print_arguments
  args = ARGV

  if args.empty?
    puts "No arguments provided."
  else
    args.each_with_index do |arg, index|
      puts "#{index + 1}. #{arg}"
    end
  end
end
