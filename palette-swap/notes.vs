#BEGIN IGNORECODE

A simple algorithm that gives reasonably good results:

Add the squared difference of each color component (red, green, blue) between the color you are looking for and the color in your list of colors and choose 

the color where the sum of those squared differences is minimal.

For a more accurate result, see the wikipedia article on color difference and implement one of the algorithms described there.

(Square(Red(source)-Red(target))) + (Square(Green(source)-Green(target))) + (Square(Blue(source)-Blue(target)))
