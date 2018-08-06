require_relative 'test_helper'

require_relative '../lib/path_builder'


class PathBuilderTest < Minitest::Test
  def test_paths
    assert_equal "data_000", PathBuilder.calculate(103)
    assert_equal "data_001", PathBuilder.calculate(1003)

    assert_equal "data_999", PathBuilder.calculate(999_999)

    assert_equal "data_000/data_000", PathBuilder.calculate(1_000_000)
    assert_equal "data_000/data_001", PathBuilder.calculate(1_001_000)
    assert_equal "data_000/data_010", PathBuilder.calculate(1_010_000)
    assert_equal "data_000/data_100", PathBuilder.calculate(1_100_000)
    assert_equal "data_000/data_999", PathBuilder.calculate(1_999_999)

    assert_equal "data_001/data_000", PathBuilder.calculate(2_000_000)
    assert_equal "data_001/data_001", PathBuilder.calculate(2_001_000)
    assert_equal "data_001/data_010", PathBuilder.calculate(2_010_000)

    assert_equal "data_019/data_010", PathBuilder.calculate(20_010_000)

    assert_equal "data_199/data_010", PathBuilder.calculate(200_010_000)

    assert_equal "data_899/data_010", PathBuilder.calculate(900_010_000)
    assert_equal "data_999/data_010", PathBuilder.calculate(1_000_010_000)
    assert_equal "data_999/data_999", PathBuilder.calculate(1_000_999_999)
  end

  def test_max_index
    assert_raises PathBuilder::MaxFiles do
      PathBuilder.calculate(1_001_000_000)
    end
  end
end
