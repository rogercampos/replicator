class PathBuilder
  MaxFiles = Class.new(StandardError)
  MAX_PER_FOLDER = 1_000
  LIMIT = MAX_PER_FOLDER * (MAX_PER_FOLDER + MAX_PER_FOLDER * MAX_PER_FOLDER)

  def self.calculate(index)
    level1 = index / (MAX_PER_FOLDER * MAX_PER_FOLDER)

    if index >= LIMIT
      raise MaxFiles, "Sorry, max #{LIMIT} files allowed!"
    end

    if level1.zero?
      level0 = index / MAX_PER_FOLDER
      "data_#{level0.to_s.rjust(3, "0")}"
    else
      level0 = (index - MAX_PER_FOLDER * MAX_PER_FOLDER * level1) / MAX_PER_FOLDER
      "data_#{(level1 - 1).to_s.rjust(3, "0")}/data_#{level0.to_s.rjust(3, "0")}"
    end
  end
end