#!/usr/bin/ruby
# Encoding: UTF-8
# Wubi Tester for Ruby
# (You need a Ruby interpreter installed on your system, for detailed instructions see ruby-lang.org)
# A simple script intended for Chinese and overseas students to learn
# Wubi input method, an innovative and very fast method of typing Chinese texts.
# Usage: ruby tester.rb [BASE]
# The script will ask you to type in the corresponding code for every character appearing on the screen.
# The script only works in command line.
# Feel free to introduce any changes you consider necessary.
# Input file format: [Character] <TAB> [ANSWER1] <TAB> [ANSWER2] <NEWLINE>
# Written by Karol Moroz (dmuhafc (at) gmail (dot) com), May 2014

require 'io/console'

class Game
	attr_reader :count, :position

	def initialize
		@baza = [] # An array of all the questions in the base
		@points_correct = 0 # The count of correct answers
		@points_wrong = 0 # Analogically
		@queue = [] # What you really will answer
		@to_revise = {}
		@revising = false
		@next_base = [] # For questions you answer wrong, all of them will be logged and revised after you're done with the current base
		@tte = 0.0 #Total time elapsed
		@counter = 0 #Counting the questions already answered
		@round = 1
		@data_dir = "data"
	end

	def load(filename)
		if File.exists? "./#{filename}"
			path = filename
		else
			path = "#{@data_dir}/#{filename}"
		end
		source = File.new path, "r:UTF-8"
		source.each do |line|
			if line =~ /no shuffling/i
				@noshuffling = true
				next
			end
			text = line.chomp.split(/\t+/)
			q = text[0]
			a = text - [text[0]]
			add_question q,a
		end
		source.close
	end
	
	def mean_time
		@tte/@counter
	end

	def count_time
		@time_elapsed = Time.now - @starting_time
		@tte += @time_elapsed # total time elapsed
		@counter += 1
	end

	def start
		#p @baza
		@queue = @baza
		@queue.shuffle! unless @noshuffling
		@position = 0
		@count = @queue.count
		puts "Welcome to Wubi trainer. For each character given, please input the corresponding Wubi code and press [Enter]."
		puts "To break the game, type \"exit\" and press [Enter]."
	end

	def restart
		@queue = @next_base
		@queue.shuffle! unless @noshuffling
		@position = 0
		log
		@next_base = []
		@to_revise = {}
		puts "Going on!"
	end

	def ask
		unless @to_revise[@position].nil?
			@revising = true
			ask_question(@to_revise[@position])
		else
			ask_question(@queue[@position])
			@position += 1
		end
	end

	def goodbye
		puts score
		#puts "To revise: " + @next_base.join(", ") + "."
		log
		exit
	end

	def add_for_revision(question)
		unless @revising
			@to_revise[@position+5] = question
			@to_revise[@position+15] = question
			@to_revise[@position+30] = question
			@next_base += [question]
		end
	end

	def read_answer
		answer = ""
		loop do
			key = STDIN.getch
			case key
				when /[a-zA-z]/ then
					answer += key
					print key
				when "\r", " " then
					puts
					return answer
				when "\x7F" then
					answer = answer[0..-2]
					print "\b \b"
			end
		end
	end

	def ask_question(question)
		puts question[:q]
		@starting_time = Time.now
		answer = read_answer
		goodbye if answer.downcase == "exit"
		if question[:a].class == String
			if question[:a] == answer.downcase
				count_time
				correct
			else
				count_time
				wrong(question[:a])
				add_for_revision(question)
			end
		elsif question[:a].class == Array
			for i in question[:a]
				if i == answer.downcase
					count_time
					correct
					break
				else
					count_time
					wrong(question[:a])
					add_for_revision(question)
					break
				end
			end
		end
		@to_revise[@position] = nil
		@revising = false
	end

	def correct
		@points_correct += 1
		puts "That's the correct answer!"
		puts score
	end

	def log
		Dir.mkdir "log" unless Dir.exists?("log")
		@logfile = File.new(Time.now.strftime("log/%y%m%d-%H%M%S.txt"), "w") if @logfile.nil?
		@logfile.puts "### ROUND #{@round}"
		for item in @next_base
			@logfile.puts item[:q] + "\t" + item[:a].join("\t")
		end
		# logfile.close
	end

	def wrong(correct_answer)
		@points_wrong += 1
		if correct_answer[0] == correct_answer[1] or correct_answer.count == 1
			puts "Wrong, the correct answer is " + correct_answer[0] + "!"
		else
			puts "Wrong, the correct answers are " + correct_answer.join(", ") + "!"
		end
		puts score
	end

	def score
		correctness = (@points_correct.to_f/(@points_correct+@points_wrong)*100).round(1)
		str = "Correct: #{@points_correct}, wrong: #{@points_wrong}. Correctness ratio: " + correctness.to_s + "%.\n"
		str << "Time elapsed: " + @time_elapsed.round(3).to_s + " s. "
		str << "Mean time: #{mean_time.round(3)} s.\n"
		str << "Questions remaining: #{@queue.count-@position}"
	end

	def add_question(q, a)
		if a.class == String
			a = a.lowercase
		else
			a.each do |item|
				item = item.downcase
			end
		end
		question = {:q => q, :a => a}
		@baza += [question]
	end
end

game = Game.new
if ARGV.empty?							# if no file given, load all files in the directory "data"
	datafiles = Dir.glob "data/*-*.txt"
elsif ARGV[0] =~ /(\d+)/
	datafiles = (Dir.glob "data/*-*.txt").shuffle
	number = $1.to_i/100
	datafiles = datafiles[0..number-1]
else
	datafiles = ARGV
end
for file in datafiles
	game.load(file)
end

game.start
loop do
	game.ask
	game.restart if game.position == game.count - 1
end
