namespace :content_based_recommend do
  desc '本のデータを分かち書きにする'
  task :wakati => :environment do
    mecab = Natto::MeCab.new
    books = Book.all

    # tf

    words_list = []
    df = {}
    tf = []
    word_count = []
    tf_idf = []
    count_flag = {}
    books.each do |book|
      if book.description.present?
        sentence = book.name + " " + book.description
      else
        sentence = book.name
      end

      word_frequency = {}
      words = 0

      df.each do |word, _|
        count_flag[word] = false
      end

      mecab.parse(sentence) do |n|
        if n.feature.match(/名詞/)
          print(n.surface + '  ')
          words_list.append(n.surface)
          words += 1

          if word_frequency.has_key?(n.surface)
            word_frequency[n.surface] = 1
          else
            word_frequency[n.surface] += 1
          end

          if df.keys.include?(n.surface)
            if count_flag[n.surface] == false
              df[n.surface] += 1
              count_flag[n.surface] += true
            end
          else
            df[n.surface] = 1
            count_flag[n.surface] += 1
          end
          tf.append(word_frequency)
          word_count.append(words)
        end
      end

      tf.each do |id, word_frequency|

      end

    end
  end
end

