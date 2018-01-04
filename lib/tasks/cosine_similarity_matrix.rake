namespace :cosine_similarity_matrix do
  desc '行列からレコメンドさせてみる'
  task :calculate => :environment do
    require 'matrix'
    # book_id = args.book_id
    matrix = load_hash('matrix')[:matrix]
    desc_matrix = load_hash('desc_matrix')[:matrix]
    matrix_list = []
    p matrix.size
    matrix.each_with_index do |vector, index|
      matrix_list.push(vector)
    end
    p matrix_list
    p desc_matrix.size
    matrix_v2 = Matrix[*matrix_list]
    p matrix_v2
    similarity = matrix_v2 * matrix_v2.transpose

    p similarity

    # Redis.current.set("books/recommends/#{book.id}", max_score.map {|k| k[:index]})
  end

  desc 'book_idからレコメンドさせる(計算初期化)'
  task :generate_recommend => :environment do
    # book_id = args.book_id
    # Rake::Task['title_based_recommend:generating_matrix'].execute
    # Rake::Task['description_based_recommend:generating_matrix'].execute
    Rake::Task['content_based_recommend:calculate_matrix_recommend'].execute
  end
end

