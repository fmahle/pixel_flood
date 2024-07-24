require "ncurses"

ROWS = 14
COLUMNS = 14
COLORS = 6

struct Coordinate
  property y, x

  def initialize(@y : Int32, @x : Int32)
  end
end

class Area
  property neighbors
  getter color
  property coordinates : Array(Coordinate)

  def initialize(@color : Int32, y, x)
    @neighbors = Array(Area).new
    @coordinates = [Coordinate.new(y, x)]
  end

  def merge(area : Area)
    @neighbors.concat(area.neighbors)
    @coordinates.concat(area.coordinates)
  end

  def contact(area : Area)
    return if area == self
    @neighbors.push area
    area.neighbors.push self
    @neighbors.uniq!
    area.neighbors.uniq!
  end

  def set_color(color : Int32, matrix : Array(Array(Area)))
    @color = color
    @neighbors.dup.select{ |neighbore| neighbore.color == color }.each do |neighbore|
      self.merge(neighbore)
      neighbore.coordinates.each do |coordinate|
        matrix[coordinate.y][coordinate.x] = self
      end
    end
    @neighbors.uniq!
  end
end

def generate_matrix
  matrix = Array(Array(Area)).new(ROWS) do |row|
    Array(Area).new(COLUMNS) do |column|
      Area.new(rand(1..COLORS), row, column)
    end
  end

	row = 0
  loop do
    (COLUMNS - 1).times do |column|
      if matrix[row][column].color == matrix[row][column + 1].color && matrix[row][column] != matrix[row][column + 1]
        matrix[row][column].merge(matrix[row][column + 1])
        area = matrix[row][column]
        matrix[row][column + 1].coordinates.each do |coordinate|
          matrix[coordinate.y][coordinate.x] = area
        end
      end
    end

		break if row == ROWS - 1

    COLUMNS.times do |column|
      if matrix[row][column].color == matrix[row + 1][column].color && matrix[row][column] != matrix[row + 1][column]
        matrix[row][column].merge(matrix[row + 1][column])
        area = matrix[row][column]
        matrix[row + 1][column].coordinates.each do |coordinate|
          matrix[coordinate.y][coordinate.x] = area
        end
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

NCurses.open do
  # initialize
  NCurses.cbreak
  NCurses.noecho
  NCurses.start_color

  # define background color
  pair = NCurses::ColorPair.new(1).init(NCurses::Color::WHITE, NCurses::Color::BLACK)
  
  pairs = [NCurses::ColorPair.new(2).init(NCurses::Color::BLACK, NCurses::Color::RED    ),
           NCurses::ColorPair.new(3).init(NCurses::Color::BLACK, NCurses::Color::BLUE   ),
           NCurses::ColorPair.new(4).init(NCurses::Color::BLACK, NCurses::Color::GREEN  ),
           NCurses::ColorPair.new(5).init(NCurses::Color::BLACK, NCurses::Color::MAGENTA),
           NCurses::ColorPair.new(6).init(NCurses::Color::BLACK, NCurses::Color::YELLOW ),
           NCurses::ColorPair.new(7).init(NCurses::Color::BLACK, NCurses::Color::CYAN   )]

  NCurses.bkgd(pair)

  matrix = generate_matrix

  NCurses.erase

  loop do
    ROWS.times do |i|
      COLUMNS.times do |j|
        NCurses.attron(pairs[matrix[i][j].color - 1].attr)
        NCurses.move(y: i, x: j * 2)
        NCurses.addstr(" " + matrix[i][j].color.to_s)
      end
    end
    NCurses.refresh
    input = NCurses.getch.to_i - 48
    break if !(1..COLORS).includes?(input)
    NCurses.erase
    matrix[0][0].set_color(input, matrix)
  end

  NCurses.notimeout(true)
  NCurses.getch
end
