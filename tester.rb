#!/usr/bin/ruby
# Encoding: UTF-8

class Game
	attr_reader :count, :position

	def initialize
		@baza = []
		@points_correct = 0
		@points_wrong = 0
		@queue = []
		@to_revise = {}
		@revising = false
		@next_base = []
		@times = []
	end

	def load(filename = "baza.txt")
		source = File.new filename
		source.each do |line|
			text = line.chomp.split(/\t+/)
			q = text[0]
			a = text - [text[0]]
			add_question q,a
		end
		source.close
	end
	
	def mean_time
		sum = 0.0
		for i in @times
			sum += i
		end
		sum/@times.count
	end

	def count_time
		@time_elapsed = Time.now - @starting_time
		@times += [@time_elapsed]
	end

	def start
		#p @baza
		@queue = @baza.shuffle
		@position = 0
		@count = @queue.count
		puts "Welcome to Wubi trainer. For each character given, please input the corresponding Wubi code and press [Enter]."
		puts "To break the game, type \"exit\" and press [Enter]."
	end

	def restart
		@queue = @next_base.shuffle
		@position = 0
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
		puts "To revise: " + @next_base.join(", ") + "."
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

	def ask_question(question)
		puts question[:q]
		@starting_time = Time.now
		answer = STDIN.gets.chomp
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
		str << "Mean time: #{mean_time.round(3)} s."
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
unless ARGV.empty?
	for file in ARGV
		game.load(file)
	end
else
	game.load
end
game.start
loop do
	game.ask
	game.restart if game.position == game.count - 1
end