require "hancli/version"
require 'rainbow'

class String
	def strip_tone
		self.gsub(/[0-5]/, '').gsub(' ','')
	end
end

module Hancli
	class Terminal
		def self.clear
			system('clear')
		end
		def self.clear_fast
			system('sleep 0.6 && clear')
		end
		def self.clear_slow
			system('sleep 2 && clear')
		end
	end
	class Answer
		def initialize(pinyin_num)
			@answer = gets.chomp
			@pinyin_num = pinyin_num
		end
		def correct?
			@answer.capitalize == @pinyin_num.capitalize
		end
		def tone_correct?
			@answer.strip_tone.capitalize == @pinyin_num.strip_tone.capitalize
		end
	end
	
	class Word
		attr_reader :simpl
		attr_accessor :attempts, :guess
		def initialize(simpl, trad, pinyin_num, pinyin, eng, attempts, guess)
			@simpl = simpl
			@trad = trad
			@pinyin = pinyin
			@pinyin_num = pinyin_num
			@eng = eng
			@attempts = attempts.to_i
			@guess = guess.to_i
		end
		def to_s
			[@simpl, @pinyin, @eng, rate].join("\t")
		end
		def to_csv
			[@simpl, @attempts, @guess].join(",")
		end
		def rate
			return 0.0 if @attempts == 0
			@guess.to_f/@attempts.to_f
		end
		def evaluate
			print @simpl + "\t"
			answer = Answer.new(@pinyin_num)
			if answer.correct?
				@guess += 1
				puts Rainbow(".....").green
				puts self.to_s
				Terminal.clear_fast
			else
				if answer.tone_correct?
					puts Rainbow(".....").yellow
				else
					puts Rainbow(".....").red
				end
				puts self.to_s
				Terminal.clear_slow
			end
			@attempts += 1
		end
	end
	
	class WordList
		def initialize(words_file, progress_file)
			@words_file = words_file
			@progress_file = progress_file
			@words = []
			load_words
		end
		def load_progress
			progress = {}
			if File.exist?(@progress_file)
				File.open(@progress_file).each_line do |l|
					simpl, attempts, guess = l.rstrip.split(",")
					progress[simpl] = {attempts: attempts.to_i, guess: guess.to_i}
				end
			end
			progress
		end
		def load_words
			progress = load_progress
			File.open(@words_file).each_line do |l|
				simpl, trad, pinyin_num, pinyin, eng = l.rstrip.split("\t")
				w = Word.new(simpl, trad, pinyin_num, pinyin, eng, 0, 0)
				if progress.has_key?(simpl)
					p = progress[simpl]
					w.attempts = p[:attempts]
					w.guess = p[:guess]
				end
				@words << w
			end
		end
		def save
			File.open(@progress_file, "w") do |f|
				@words.each{|w| f.puts w.to_csv}
			end
		end
		def evaluate_word
			w = @words.sort_by{|w| w.rate}.first
			w.evaluate
			self.save
			w
		end
		def play(num)
			played_words = []
			num.times do
				played_words << self.evaluate_word
			end
			played_words.each do |w|
				puts w.to_s
			end	
		end
	end
end
