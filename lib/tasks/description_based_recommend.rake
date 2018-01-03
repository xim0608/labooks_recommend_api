namespace :description_based_recommend do
  def save_object!(obj, name)
    File.open("desc_#{name}", 'wb') do |file|
      Marshal.dump(obj, file)
    end
  end

  def load_hash(name)
    hash = {}
    File.open("#{Rails.root}/desc_#{name}.data", 'rb') do |file|
      hash = Marshal.load(file)
    end
    return hash
  end

  desc '本の書籍名と詳細を分かち書き'
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
    stop_word += ['版']
    stop_word += [*1..10].map(&:to_s)

    mecab = Natto::MeCab.new
    books = Book.all

    word_list = []

    # tf = ある単語tがある文書に現れる回数 / ある文書中の全ての単語数
    # idf = log(比較する文書の総数N / ある単語が現れた文書数)
    all_count = {}

    books.each do |book|
      if book.description.present?
        sentence = book.name + ' ' + book.description
      else
        sentence = book.name
      end

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
    sub_tfstore = {}
    merge_idf = {}
    merge_tfidf = {}

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
    save_object!(merge_tfidf, 'tfidf.data')
  end

  desc 'tf-idfを値とした行列(ユニーク単語数x冊数)を作成'
  task :tf_idf_vector => :environment do
    books_tfidf = load_hash('tfidf')

    count_data = load_hash('count')
    word_list = count_data[:word_list]
    uniq_word_list = word_list.flatten!.uniq!
    vector = Array.new(count_data[:all_count].keys.last+1).map{Array.new(uniq_word_list.size, 0)}
    # vector[0]は空のベクトル(book_idは1から)
    books_tfidf.each do |book_id, keywords|
      keywords.each do |keyword, tf_idf|
        uniq_word_list_index = uniq_word_list.index(keyword)
        vector[book_id][uniq_word_list_index] = tf_idf
      end
    end
    p vector
    matrix = {matrix: vector}
    save_object!(matrix, 'matrix.data')
  end

  desc '行列を生成する'
  task :generating_matrix do
    Rake::Task['description_based_recommend:wakati'].execute
    Rake::Task['description_based_recommend:calculate_tf_idf'].execute
    Rake::Task['description_based_recommend:tf_idf_vector'].execute
  end
end
