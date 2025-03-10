require "ncurses"

ROWS = 14
COLUMNS = 14
COLORS = 6

struct Coordinate
  property y, x

  def initialize(@y : UInt32, @x : UInt32)
  end
end

class Area
  property neighbors
  property color
  property coordinates : Array(Coordinate)

  def initialize(@color : UInt32, y, x)
    @neighbors = StaticArray(Set(Area), COLORS).new { Set(Area).new }
    @coordinates = [Coordinate.new(y, x)]
  end

  def contact(area : Area)
    return if area == self
    @neighbors[area.color].add(area)
    area.neighbors[@color].add(self)
  end

  def merge(area : Area, matrix : Array(Array(Area)))
    area.coordinates.each do |coordinate|
      matrix[coordinate.y][coordinate.x] = self
    end
    @coordinates.concat(area.coordinates)

    COLORS.times do |color|
      @neighbors[color].concat(area.neighbors[color])
      area.neighbors[color].each do |neighbore|
        neighbore.neighbors[area.color].delete(area)
      end
    end
    @neighbors[area.color].delete(area)
    @neighbors[@color].delete(self)
  end

  def set_color(color, matrix : Array(Array(Area)))
    foo = @neighbors[color].size > 0
    @neighbors[color].each do |neighbore|
      self.merge(neighbore, matrix)
    end
    @color = color
    foo
  end
end

def generate_matrix
  matrix = Array(Array(Area)).new(ROWS) do |row|
    Array(Area).new(COLUMNS) do |column|
      Area.new(rand(0..(COLORS - 1)).to_u, row.to_u, column.to_u)
    end
  end

	row = 0
  loop do
    (COLUMNS - 1).times do |column|
      if matrix[row][column].color == matrix[row][column + 1].color && matrix[row][column] != matrix[row][column + 1]
        matrix[row][column].merge(matrix[row][column + 1], matrix)
      end
    end

		break if row == ROWS - 1

    COLUMNS.times do |column|
      if matrix[row][column].color == matrix[row + 1][column].color && matrix[row][column] != matrix[row + 1][column]
        matrix[row][column].merge(matrix[row + 1][column], matrix)
      end
    end

    row += 1
  end

  row = 0
  loop do
    (COLUMNS - 1).times do |column|
      matrix[row][column].contact(matrix[row][column + 1])
    end

    break if row == ROWS - 1

    COLUMNS.times do |column|
      matrix[row][column].contact(matrix[row + 1][column])
    end

    row += 1
  end

  matrix
end

moves = 0
success = false

NCurses.open do
  NCurses.cbreak
  NCurses.noecho
  NCurses.start_color

  pair = NCurses::ColorPair.new(1).init(NCurses::Color::WHITE, NCurses::Color::BLACK)
  
  pairs = [NCurses::ColorPair.new(2).init(NCurses::Color::BLACK, NCurses::Color::GREEN  ),
           NCurses::ColorPair.new(3).init(NCurses::Color::BLACK, NCurses::Color::CYAN   ),
           NCurses::ColorPair.new(4).init(NCurses::Color::BLACK, NCurses::Color::BLUE   ),
           NCurses::ColorPair.new(5).init(NCurses::Color::BLACK, NCurses::Color::MAGENTA),
           NCurses::ColorPair.new(6).init(NCurses::Color::BLACK, NCurses::Color::RED    ),
           NCurses::ColorPair.new(7).init(NCurses::Color::BLACK, NCurses::Color::YELLOW )]


  NCurses.bkgd(pair)

  matrix = generate_matrix

  loop do
    NCurses.erase
    ROWS.times do |i|
      COLUMNS.times do |j|
        NCurses.attron(pairs[matrix[i][j].color].attr)
        NCurses.mvaddstr(" " + (matrix[i][j].color + 1).to_s, y: i, x: j * 2)
      end
    end

    NCurses.refresh

    highest_neighbore_count = 0
    highest_neighbore_count_color = nil

    matrix[0][0].neighbors.each_with_index do |neighbors, color|
      neighbore_count = (neighbors.map{ |color_neighbore| color_neighbore.neighbors.sum }.sum - matrix[0][0].neighbors.sum).size
      if neighbore_count > highest_neighbore_count
        highest_neighbore_count = neighbore_count
        highest_neighbore_count_color = color.to_u
      end
    end

    highest_neighbore_count_color ||= (matrix[0][0].neighbors.index{ |neighbors| neighbors.size > 0} || 0).to_u

    NCurses.attron(pairs[highest_neighbore_count_color].attr)
    NCurses.mvaddstr(moves.to_s + " " + matrix.flatten.uniq.size.to_s, y: ROWS, x: COLUMNS * 2)

    NCurses.refresh

    input = NCurses.getch.to_i

    if 48 < input < 49 + COLORS
      moves += 1 if matrix[0][0].set_color(input.to_u - 49, matrix)
    elsif input == 97
      moves += 1 if matrix[0][0].set_color(highest_neighbore_count_color, matrix)
    else
      break
    end

    if matrix.flatten.uniq.size == 1
      success = true
      break
    end
  end

  NCurses.notimeout(true)
end

puts moves if success
