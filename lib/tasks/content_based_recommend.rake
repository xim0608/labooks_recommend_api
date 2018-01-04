namespace :content_based_recommend do
  desc '行列からレコメンドさせてみる'
  task :calculate_matrix_recommend => :environment do
    require 'matrix'
    # book_id = args.book_id
    matrix = load_hash('matrix')[:matrix]
    all_count = load_hash('count')[:all_count]

    desc_matrix = load_hash('desc_matrix')[:matrix]
    # desc_all_count = load_hash('desc_count')[:all_count]

    books = Book.all
    books.each do |book|
      next if Redis.current.get("books/recommends/#{book.id}").present?
      threshold = 0.35
      base_vec = Vector.elements(matrix[book.id])
      desc_base_vec = Vector.elements(desc_matrix[book.id])

      max_score = Array.new(6, {score: 0, index: 0, type: 'title'})

      matrix.each_with_index do |vector, index|
        score = base_vec.inner_product(Vector.elements(vector)).fdiv(base_vec.norm * Vector.elements(vector).norm)
        max_score.sort! {|a, b| a[:score] <=> b[:score]}
        next if score >= 0.98
        if max_score[0][:score] < score && score >= threshold
          max_score.shift
          max_score.push({score: score, index: index, type: 'title'})
        end
      end
      desc_matrix.each_with_index do |vector, index|
        score = desc_base_vec.inner_product(Vector.elements(vector)).fdiv(desc_base_vec.norm * Vector.elements(vector).norm)
        max_score.sort! {|a, b| a[:score] <=> b[:score]}
        next if score >= 0.98
        next if max_score.map {|k| k[:index]}.include?(index)
        if max_score[0][:score] < score
          max_score.shift
          max_score.push({score: score, index: index, type: 'description'})
        end
      end
      p "Base: #{book.name}"
      max_score.delete({score: 0, index: 0, type: 'title'})
      max_score.each do |score|

        score.each do |k, v|
          if k == :index
            p Book.find(v).name
            p all_count[v]
          elsif k == :score
            p "score: #{v}"
          else
            p v
            p '=================='
          end
        end
      end
      Redis.current.set("books/recommends/#{book.id}", max_score.map {|k| k[:index]})
    end
  end

  desc '行列からレコメンドさせてみる'
  task :calculate_sparse_matrix => :environment do
    require 'matrix'
    # book_id = args.book_id
    matrix = load_hash('sparse_matrix')[:matrix]
    all_count = load_hash('count')[:all_count]

    desc_matrix = load_hash('desc_sparse_matrix')[:matrix]
    # desc_all_count = load_hash('desc_count')[:all_count]

    books = Book.all
    books.each do |book|
      # next if Redis.current.get("books/sparse_recommends/#{book.id}").present?
      threshold = 0.35
      base_vec = matrix[book.id]
      desc_base_vec = desc_matrix[book.id]

      max_score = Array.new(6, {score: 0, index: 0})
      matrix.each_with_index do |vector, index|
        next if vector.nil?
        next if index == 0
        next if index == book.id
        double = vector[0] & base_vec[0]
        score = 0
        double.each do |s|
          score += vector[1][vector[0].index(s)] * base_vec[1][base_vec[0].index(s)]
        end
        score = score.fdiv(Math.sqrt(base_vec[1].reduce(0) {|vec, s| vec += s ** 2} * vector[1].reduce(0) {|vec, s| vec += s ** 2}))
        next if score > 0.98
        max_score.sort! {|a, b| a[:score] <=> b[:score]}
        if max_score[0][:score] < score
          max_score.shift
          max_score.push({score: score, index: index})
        end
      end
      # max_score.each do |score|
      #   score = {score: 0, index: 0} if score[:score] < 0.20
      # end
      p max_score
      max_score.map! do |score|
        if score[:score] < 0.20
          {score: 0, index: 0}
        else
          score
        end
      end
      p max_score
      if max_score.count({score: 0, index: 0}) > 0
        title_recommend_index = max_score.map {|s| s[:index]}
        desc_matrix.each_with_index do |vector, index|
          next if vector.nil?
          next if index == 0
          next if index == book.id
          next if title_recommend_index.include?(index)
          double = vector[0] & base_vec[0]
          score = 0
          double.each do |s|
            score += vector[1][vector[0].index(s)] * base_vec[1][base_vec[0].index(s)]
          end
          score = score.fdiv(Math.sqrt(base_vec[1].reduce(0) {|vec, s| vec += s ** 2} * vector[1].reduce(0) {|vec, s| vec += s ** 2}))
          max_score.sort! {|a, b| a[:score] <=> b[:score]}
          if max_score[0][:score] < score
            max_score.shift
            max_score.push({score: score, index: index})
          end
        end
      end
      p "===================="

      p "Base: #{book.name}"
      p max_score.size
      max_score.delete({score: 0, index: 0})
      # p max_score
      max_score.each do |score|
        score.each do |k, v|
          if k == :index
            p Book.find(v).name
            p all_count[v]
            p score
          elsif k == :score
            p "score: #{v}"
          else
            # p v
          end
        end
      end
      p "===================="

      Redis.current.set("books/sparse_recommends/#{book.id}", max_score.map {|k| k[:index]})
    end
  end

  desc 'book_idからレコメンドさせる(計算初期化)'
  task :generate_recommend => :environment do
    # book_id = args.book_id
    # Rake::Task['title_based_recommend:generating_matrix'].execute
    # Rake::Task['description_based_recommend:generating_matrix'].execute
    Rake::Task['content_based_recommend:calculate_matrix_recommend'].execute
  end
end

