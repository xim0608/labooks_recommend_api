namespace :content_based_recommend do
  desc '行列からレコメンドさせてみる'
  task :calculate_recommend, ['book_id'] => :environment do |task, args|
    require 'matrix'
    book_id = args.book_id
    matrix = load_hash('matrix')[:matrix]
    all_count = load_hash('count')[:all_count]

    desc_matrix = load_hash('desc_matrix')[:matrix]
    # desc_all_count = load_hash('desc_count')[:all_count]

    book = Book.find(book_id)
    threshold = 0.25
    base_vec = Vector.elements(matrix[book.id])
    desc_base_vec = Vector.elements(desc_matrix[book.id])

    max_score = Array.new(3, {score: 0, index: 0, type: 'title'})

    matrix.each_with_index do |vector, index|
      score = base_vec.inner_product(Vector.elements(vector)).fdiv(base_vec.norm * Vector.elements(vector).norm)
      max_score.sort! {|a, b| a[:score] <=> b[:score]}
      next if score >= 1.to_f
      if max_score[0][:score] < score && score >= threshold
        max_score.shift
        max_score.push({score: score, index: index, type: 'title'})
      end
    end
    desc_matrix.each_with_index do |vector, index|
      score = desc_base_vec.inner_product(Vector.elements(vector)).fdiv(desc_base_vec.norm * Vector.elements(vector).norm)
      max_score.sort! {|a, b| a[:score] <=> b[:score]}
      next if score >= 1.to_f
      if max_score[0][:score] < score
        max_score.shift
        max_score.push({score: score, index: index, type: 'description'})
      end
    end
    p "Base: #{book.name}"
    max_score.each do |score|
      score.each do |k, v|
        if k == :index
          p Book.find(v).name
          p all_count[v]
        elsif k == :score
          p "score: #{v}"
        else
          p type
          p '=================='
        end
      end
    end
  end

  desc 'book_idからレコメンドさせる(計算初期化)'
  task :fetch_recommend, ['book_id'] => :environment do |task, args|
    book_id = args.book_id
    Rake::Task['title_based_recommend:generating_matrix'].execute
    Rake::Task['description_based_recommend:generating_matrix'].execute
    Rake::Task['content_based_recommend:calculate_recommend'].execute(Rake::TaskArguments.new([:book_id], [book_id]))
  end
end

