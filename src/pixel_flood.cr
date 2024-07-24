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

  def merge(area : Area, matrix : Array(Array(Area)))
    area.coordinates.each do |coordinate|
      matrix[coordinate.y][coordinate.x] = self
    end
    @coordinates.concat(area.coordinates)
    COLORS.times do |color|
      @neighbors[color].concat(area.neighbors[color])
    end
    @neighbors[area.color].delete(area)
    @neighbors[@color].delete(self)
  end

  def contact(area : Area)
    return if area == self
    @neighbors[area.color].add(area)
    area.neighbors[@color].add(self)
  end

  def set_color(@color, matrix : Array(Array(Area)))
    @neighbors[@color].each do |neighbore|
      self.merge(neighbore, matrix)
    end
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

  NCurses.erase

  input = -1
  loop do
    ROWS.times do |i|
      COLUMNS.times do |j|
        NCurses.attron(pairs[matrix[i][j].color].attr)
        NCurses.move(y: i, x: j * 2)
        NCurses.addstr(" " + (matrix[i][j].color + 1).to_s)
      end
    end
    NCurses.refresh
    old_input = input
    input = (NCurses.getch.to_i - 49).to_u
    break if !(0..(COLORS - 1)).includes?(input)
    if old_input != input
      moves += 1
    end
    NCurses.erase
    matrix[0][0].set_color(input, matrix)
  end

  NCurses.notimeout(true)
  NCurses.getch
end

puts moves
