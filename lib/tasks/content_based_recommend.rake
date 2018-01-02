namespace :content_based_recommend do
  def save_object(obj, name)
    File.open(name, 'wb') do |file|
      Marshal.dump(obj, file)
    end
  end

  desc '本の書籍名からtf-idfを算出する'
  task :wakati => :environment do
    include Math
    require 'natto'
    require 'matrix'

    stop_word = []
    File.open("#{Rails.root}/lib/tasks/Japanese.txt") do |file|
      file.each_line do |word|
        stop_word << word.strip if word.present?
      end
    end

    mecab = Natto::MeCab.new
    books = Book.take(10)

    # 本ごとの分かち書きのリスト(index: book_id)
    word_list = []


    # tf = ある単語tがある文書に現れる回数 / ある文書中の全ての単語数
    # idf = log(比較する文書の総数N / ある単語が現れた文書数)

    tf_store = {}
    idf_store = {}
    all_count = {}
    sub_tfstore = {}
    tf_counter = {}
    sub_idf = {}
    merge_idf = {}
    merge_tfidf = {}
    tfidf = {}


    books.each do |book|
      # if book.description.present?
      #   sentence = book.name + " " + book.description
      # else
      sentence = book.name
      # end

      wakatigaki = []
      mecab.parse(sentence) do |n|
        if n.feature.match(/名詞/)
          # print(n.surface + '  ')
          wakatigaki << n.surface unless stop_word.include?(n.surface)
        end
      end
      word_list.append(wakatigaki)

      word_count = {}
      wakatigaki.each do |word|
        if word_count.has_key?(word)
          all_count[book.id] = word_count[word]
        else
          word_count[word] = 0
          all_count[book.id] = 0
        end
        word_count[word] += 1
      end
      all_count[book.id] = word_count
    end
    p all_count
    # p word_list

    # word_list.each_with_index do |book_words, i|
    #   word_count = {}
    #   book_words.each do |word|
    #     if word_count.has_key?(word)
    #       all_count[i] = word_count[word]
    #     else
    #       word_count[word] = 0
    #       all_count[i] = 0
    #     end
    #     word_count[word] += 1
    #   end
    #   all_count[i] = word_count
    # end
    save_object(all_count, 'word_list.data')
  end


  desc '本の書籍名からtf-idfを算出する'
  task :calculate_tf_idf => :environment do
    tf_store = {}
    idf_store = {}
    all_count = {}
    sub_tfstore = {}
    tf_counter = {}
    sub_idf = {}
    merge_idf = {}
    merge_tfidf = {}
    tfidf = {}

    all_count = {}
    File.open("#{Rails.root}/word_list.data", 'rb') do |file|
      all_count = Marshal.load(file)
    end

    # calculate words num in a document
    # word_list.each_with_index do |words, i|
    #   sum = 0
    #   all_count[i].each do |k, v|
    #     sum = sum + all_count[i][k]
    #   end
    #   sub_tfstore[i] = sum
    # end
    all_count.each do |book_id, keywords|
      sum = 0
      keywords.each do |keyword, keyword_count|
        sum += keyword_count
      end
      sub_tfstore[book_id] = sum
    end
    # print(sub_tfstore)

    # calculate tf value and set to tf_store
    # word_list.each_with_index do |_, i|
    #   counter = {}
    #   all_count[i].each do |k, v|
    #     counter[k] = all_count[i][k].to_f / sub_tfstore[i]
    #   end
    #   tf_store[i] = counter
    # end
    all_count.each do |book_id, keywords|
      counter = {}
      keywords.each do |keyword, keyword_count|
        counter[keyword] = all_count[book_id][keyword].to_f / sub_tfstore[book_id]
      end
      tf_store[book_id] = counter
    end
    p tf_store

    # word_count = {}
    # word_list.each_with_index do |_, i|
    #   word_list[i].each do |word|
    #     # print(word)
    #     word_count[word] = 0 unless word_count[word].present?
    #   end
    #   all_count[i].each do |k, v|
    #     print(k)
    #     p all_count[i]
    #     p word_count[k]
    #     word_count[k] += 1
    #   end
    #   # p word_count
    # end
    # sub_idf = word_count

    word_count = {}
    all_count.each do |book_id, keywords|
      keywords.each do |keyword|

      end
    end

    word_list.each_with_index do |_, i|
      idf_store = {}
      all_count[i].each do |k, v|

        idf_store[k] = Math.log(word_list.size / sub_idf[k].to_f)
        p sub_idf[k]
      end
      merge_idf[i] = idf_store
    end

    # p merge_idf
    word_list.each_with_index do |_, i|
      tfidf = {}
      all_count[i].each do |k, v|
        # print(tf_store[i][word])
        # print(merge_idf[i][word])
        tfidf[k] = tf_store[i][k] * merge_idf[i][k]
      end
      merge_tfidf[i] = tfidf
    end

    # p merge_tfidf
    uniq_word_list = word_list.flatten!.uniq!
    merge_tfidf.each do |book_id, v|
      # TODO: 本の元データとの照らし合わせ
      # print "#{Book.find(book_id + 1).name}: "
      # p v.sort {|(k1, v1), (k2, v2)| v2 <=> v1}
    end
    print(all_count)

  end
end
