namespace :content_based_recommend do
  def save_object!(obj, name)
    File.open(name, 'wb') do |file|
      Marshal.dump(obj, file)
    end
  end

  def load_hash(name)
    hash = {}
    File.open("#{Rails.root}/#{name}.data", 'rb') do |file|
      hash = Marshal.load(file)
    end
    return hash
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

    count_data = {all_count: all_count, word_list: word_list}
    save_object!(count_data, 'count.data')
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

    count_data = load_hash('count')
    all_count = count_data[:all_count]
    word_list = count_data[:word_list]

    all_count.each do |book_id, keywords|
      sum = 0
      keywords.each do |keyword, keyword_count|
        sum += keyword_count
      end
      sub_tfstore[book_id] = sum
    end

    all_count.each do |book_id, keywords|
      counter = {}
      keywords.each do |keyword, keyword_count|
        counter[keyword] = all_count[book_id][keyword].to_f / sub_tfstore[book_id]
      end
      tf_store[book_id] = counter
    end

    word_count = {}
    all_count.each do |book_id, keywords|
      keywords.each do |keyword, keyword_count|
        unless word_count[keyword].present?
          word_count[keyword] = 1
        else
          word_count[keyword] += 1
        end
      end
    end
    sub_idf = word_count

    all_count.each do |book_id, keywords|
      idf_store = {}
      keywords.each do |keyword, keyword_count|
        idf_store[keyword] = Math.log(all_count.size / sub_idf[keyword].to_f)
      end
      merge_idf[book_id] = idf_store
    end

    all_count.each do |book_id, keywords|
      tfidf = {}
      keywords.each do |keyword, keyword_count|
        tfidf[keyword] = tf_store[book_id][keyword] * merge_idf[book_id][keyword]
      end
      merge_tfidf[book_id] = tfidf
    end

    p merge_tfidf
    uniq_word_list = word_list.flatten!.uniq!
    merge_tfidf.each do |book_id, keywords|
      print "#{Book.find(book_id).name}: "
      p keywords.sort {|(k1, v1), (k2, v2)| v2 <=> v1}
    end
  end
end
