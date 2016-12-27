extends Node2D
#var DEBUG
#DEBUG = False
#var DIAGONAL = 1.412
#var GRASS_BLOCK = 0
#var WALL_BLOCK = 101

# Sole class needed for use of the wavefront expansion algorithm.
# Each frame where any objectives move or the map changes call
# updateObjectivesPF(), and for each WFEAObject whose velocity is due
# to be updated call getNextMovementVector"""
class WFEASearch:
	var grid
	var objectives
	#grid = the Grid this search is in, objs = the objectives in a list
	func _init(grd, objs):
		self.grid = grd
		self.objectives = objs
	# Adds an objective to the WFEA search. Linear increase in time/frame per
	# objective,depending on the radius of the objective
	
	func addObjective(obj):
		self.objectives.append(obj)
	
	# Removes an objective from the WFEA search
	func removeObjective(obj):
		self.objectives.remove(obj)
	# Updates the performance fields of each objective
	func updateObjectivesPF(counter):
		for i in range(self.objectives.size()):
			var o = self.objectives[i]
			var radius = o.radius
			var ox = o.x
			var oy = o.y
			var rad = 0
			self.grid.setDistanceValue(o, ox, oy, 0, counter)
			
			var previousExpansion = [[o.x, o.y]] # The files that were marked in the
			# last loop
			var currentExpansion = [] # The files that we are marking in this loop
			var n = true
			while rad in range(radius):
				var lenMarked = previousExpansion.size()
				for i in range(lenMarked):
					ox = previousExpansion[i][0]
					oy = previousExpansion[i][1]
					var points = self.getAdjacent(o, ox, oy, counter)
					for i in range(points.size()):
						if points[i][0] >= self.grid.width or points[i][1] >= self.grid.height:
							continue
						var resistance = self.RESIST(o, points[i][0], points[i][1], ox, oy)
						if not self.grid.isUpdated(o, points[i][0], points[i][1], counter):
							if resistance > 0:
								self.grid.setDistanceValue(o, points[i][0], points[i][1], resistance, counter)
								currentExpansion.append([points[i][0], points[i][1]])
				rad = rad + 1
				#print("End of radius", rad, "previousExpansion:", str(previousExpansion),
				#	"currentExpansion:", str(currentExpansion))
				previousExpansion = []
				for temp in range(currentExpansion.size()):
					previousExpansion.append(currentExpansion[temp])
				currentExpansion = []
				

	# Checks the location of the WFEA object and returns a vector for the
	# next location that the WFEA object should go. Normalized to [-1, 1]
	# Objective and a WFEAObject
	func getNextMovementVector(objective, obj, counter): 
		#if DEBUG:
		#	print("Checking next movement vector")
		var xBlock = int(obj.x / 32)
		var yBlock = int(obj.y / 32)
		#if DEBUG:
		#	print("Object location:", xBlock, yBlock)

		if xBlock == obj.nextDesiredBlockX and yBlock == obj.nextDesiredBlockY:
			obj.nextDesiredBlockX = -1
			obj.nextDesiredBlockY = -1
		#	if DEBUG:
		#		print("Made it to the objective")
		elif counter - obj.lastUpdated > 50:
			obj.nextDesiredBlockX = -1
			obj.nextDesiredBlockY = -1
		#	if DEBUG:
		#		print("Probably stuck")
		else:
			obj.lastUpdated = counter #deepcopy(counter)
		
		if obj.nextDesiredBlockX >= 0 and obj.nextDesiredBlockY >= 0:
		#	if DEBUG:
		#		print("Next location already set")
			var goalX = obj.nextDesiredBlockX * 32 + 8
			var goalY = obj.nextDesiredBlockY * 32 + 8
		#	if DEBUG:
		#		print("Trying to get to", goalX, goalY, "from", obj.x, obj.y)
			var dir = self.getDirectionVector(obj.x, obj.y, goalX, goalY)
			var dirX = dir[0]
			var dirY = dir[1]
		#	if DEBUG:
		#		print("Direction to go in:", dirX, dirY)
			return [dirX, dirY]
			
		var adjacent = self.getAdjacent(objective, xBlock, yBlock, counter)
		var lowest = self.grid.getDistanceValue(objective, xBlock, yBlock)
		#if DEBUG:
		#	print("Currently situated on a block with distance", lowest)
		var locationLowest = null
		for l in range(adjacent.size()):
			var loc = adjacent[l]
			if self.grid.isUpdated(objective, loc[0], loc[1], counter):
				if self.grid.getDistanceValue(objective, loc[0], loc[1]) < lowest:
					lowest = self.grid.getDistanceValue(objective, loc[0], loc[1])
					locationLowest = [loc[0], loc[1]]
		if locationLowest == null:
		#	if DEBUG:
		#		print("No adjacent blocks with a lower value, staying still")
			return [0, 0]
		else:
		#	if DEBUG:
		#		print("Found the next desired block", str(locationLowest))
			obj.nextDesiredBlockX = locationLowest[0]
			obj.nextDesiredBlockY = locationLowest[1]
			var goalX = obj.nextDesiredBlockX * 32 + 8
			var goalY = obj.nextDesiredBlockY * 32 + 8
		#	if DEBUG:
		#		print("Trying to get to", goalX, goalY, "from", obj.x, obj.y)
			var dir = self.getDirectionVector(obj.x, obj.y, goalX, goalY)
			var dirX = dir[0]
			var dirY = dir[1]
		#	if DEBUG:
		#		print("Direction to go in:", dirX, dirY)

			return [dirX, dirY]
			
	func getDirectionVector(x1, y1, x2, y2):
		var dX = x2 - x1 # delta x
		var dY = y2 - y1 # delta y
		var distance = abs(dX) + abs(dY)

		if distance == 0:
			return [0, 0]
		return [dX / distance, dY / distance]

	func RESIST(obj, x, y, ox, oy):
		var tp #!!!!!!!!!!!!!!!!!!!
		if x >= 20 or y >= 15 or x < 0 or y < 0:
			return -1
		if self.grid.getType(x, y) != Globals.get('Global/WALL_BLOCK')  and self.grid.getPassingValue(x, y) != null:
			tp = self.grid.getPassingValue(x, y)
			if ox != x and oy != y:
				tp = tp * Globals.get('Global/DIAGONAL')  
		elif self.grid.getType(x, y) == Globals.get('Global/WALL_BLOCK') and self.grid.getPassingValue(x, y) != null:
			return -1
		else:
			#print("The apocolypse has occurred") 
			return -1
		var tpn = tp + self.grid.getDistanceValue(obj, ox, oy)
		return tpn

	func getAdjacent(o, x, y, counter): 
		var points = []
		
		points.append([x, y-1]) # Order is important, diagonals come after
		points.append([x-1, y]) 
		points.append([x+1, y])
		points.append([x, y+1])

		if self.grid.getPassingValue(x, y - 1) > 0 and self.grid.getPassingValue(x + 1, y) > 0:
			points.append([x+1, y-1])

		if self.grid.getPassingValue(x, y - 1) > 0 and self.grid.getPassingValue(x - 1, y) > 0:
			points.append([x-1, y-1])

		if self.grid.getPassingValue(x, y + 1) > 0 and self.grid.getPassingValue(x + 1, y) > 0:
			points.append([x+1, y+1])

		if self.grid.getPassingValue(x, y + 1) > 0 and self.grid.getPassingValue(x - 1, y) > 0:
			points.append([x-1, y+1])

		for i in range(points.size()):
			if i >= points.size():
				continue
			var passingValue = self.grid.getPassingValue(points[i][0], points[i][1])
			if points[i][0] < 0 or points[i][1] < 0 or points[i][0] >= self.grid.width or points[i][1] >= self.grid.height or passingValue == null or passingValue < 0 or x < 0 or y < 0 or x >= self.grid.width or y >= self.grid.height:
				points.remove(i)#points.pop(i)
				i = i - 1
		return points

# A basic objective with an x location, y location, and maximum
# radius of relevance
class Objective:
	var radius
	var x
	var y
	func _init(rad):
		self.radius = rad
		self.x = 0
		self.y = 0

# Holds necessary data for the WFEASearch
#class WFEAObject:
#	func _init():
#		self.x = 0
#		self.y = 0
#		self.width = 16
#		self.height = 16
#		self.lastUpdated = 0
#		self.nextDesiredBlockX = -1
#		self.nextDesiredBlockY = -1
#		self.priority = 0

class Block:
	var mType 
	var objectiveData 
	func _init(blockType, objectiveData):
		self.mType = blockType
		self.objectiveData = objectiveData

class ObjectiveData:
	var effortToObjective 
	var lastUpdated 
	func _init():
		self.effortToObjective = 0
		self.lastUpdated = 0
		

class Grid:
	var width 
	var height 
	var objectives 
	var grid_data 
	func _init(width, height):
		self.width = width
		self.height = height
		self.objectives = []
		self.grid_data = []
		for x in range(width):
			self.grid_data.append([])
			for y in range(height):
				var newType = rand_range(0, 101)
				if newType <= 12:
					self.grid_data[x].append(Block.new(Globals.get('Global/WALL_BLOCK'), []))
				else:
					self.grid_data[x].append(Block.new(Globals.get('Global/GRASS_BLOCK'), []))
	
	func addObjective(o): # o is an Objective
		self.objectives.append(o)
		var index = self.objectives.size() - 1

		for x in range(self.width):
			for y in range(self.height):
				self.grid_data[x][y].objectiveData.append(ObjectiveData.new())

	func removeObjective(o): # o is an Objective
		var index = self.objectives.find(o) #index
		self.objectives.remove(index) #pop

		for x in range(self.width):
			for y in range(self.height):
				self.grid_data[x][y].objectiveData.remove(index)#pop

	func getPassingValue(x, y): # x is an int, y is an int
		if x < 0 or y < 0 or x >= self.width or y >= self.height:
			return -2
		var block = self.grid_data[x][y]

		if(block.mType == Globals.get('Global/GRASS_BLOCK')):
			return 10
		elif(block.mType == Globals.get('Global/WALL_BLOCK')):
			return -1
		else:
			return -2
		
	#func getDistanceValue(o, x, y, counter): # o is an objective, x, y, and counter are ints
	#	index = self.objectives.index(o)
	#	objData = self.grid[x][y].objectiveData[index]
	#	if objData.lastUpdated != counter:
	#		return -1
	#	return objData.effortToObjective
		
	func getDistanceValue(o, x, y):
		var index = self.objectives.find(o)#index(o)
		var objData = self.grid_data[x][y].objectiveData[index]
		return objData.effortToObjective
		
	func setDistanceValue(o, x, y, value, counter): # o is an objective, x, y, and counter are ints
		if x < 0 or y < 0 or x >= self.width or y >= self.height:
			return -9999999
		var index = self.objectives.find(o) #index(o)
		var objData = self.grid_data[x][y].objectiveData[index] # errors
		objData.lastUpdated = counter
		objData.effortToObjective = value
		
	func isUpdated(o, x, y, counter): # o is an objective, x, y and counter are ints
		var index = self.objectives.find(o) #index(o)
		var objData = self.grid_data[x][y].objectiveData[index]

		return objData.lastUpdated == counter
		
	func getType(x, y):
		return self.grid_data[x][y].mType
	
	func setType(x, y, newType):
		self.grid_data[x][y].mType = newType

		
# Game parameters

var SCREEN = Vector2(640, 480)
var BG_COLOR = Color(150, 170, 120)
var WALL_COLOR = Color(0.40, 0.40, 0.40)
var SQUARE_COLOR = Color(255, 255, 255)

var label = Label.new()
var font = label.get_font("")

var mGrid
var mouse
var pathFind 
var magic 
var stalkerSquares 
var counter 
var temp 

class MouseFollowingSquare: #wfea.WFEAObject
	var x = 0
	var y = 0
	var width = 16
	var height = 16
	var lastUpdated = 0
	var nextDesiredBlockX = -1
	var nextDesiredBlockY = -1
	var priority = 0
	var xVelocity 
	var yVelocity 
	func _init(x, y):
		self.x = x
		self.y = y
		self.xVelocity = 0
		self.yVelocity = 0

	func notPassable(grid, x, y):
		# First get all the blocks that are being touched
		var all_connected = [ [int(x / 32), int(y / 32)] ] 

		if int(x / 32) != int(x / 32): #x+16
			all_connected.append([all_connected[0][0] + 1, all_connected[0][1]])
			if int(y / 32) != int(y / 32): #y+16
				all_connected.append([all_connected[0][0] + 1, all_connected[0][1] + 1])

		if int(y / 32) != int(y / 32): #y+16
			all_connected.append([all_connected[0][0], all_connected[0][1] + 1])

		for i in range(all_connected.size()):
			if grid.getPassingValue(all_connected[i][0], all_connected[i][1]) < 0:
				return true
		return false

	func update(magic, mouse, grid, counter):
		var Velocity = magic.getNextMovementVector(mouse, self, counter)
		self.xVelocity = Velocity[0]
		self.yVelocity = Velocity[1]
		self.xVelocity = self.xVelocity * 3
		self.yVelocity = self.yVelocity * 3
		var nextX = self.x + self.xVelocity
		if notPassable(grid, nextX, self.y): #self.notPassable
			self.yVelocity = self.yVelocity + 0.5
			self.xVelocity = 0

		var nextY = self.y + self.yVelocity #self.notPassable
		if notPassable(grid, self.x, nextY):
			self.yVelocity = 0
			self.xVelocity = self.xVelocity + 0.5

		nextX = self.x + self.xVelocity
		nextY = self.y + self.yVelocity
		if not notPassable(grid, nextX, nextY):#self.notPassable
			self.x = nextX
			self.y = nextY
			
func spawnSquare(grid):
	var xLoc = -1
	var yLoc = -1
	while xLoc < 0 or yLoc < 0 or grid.getPassingValue(xLoc, yLoc) < 0:
		xLoc = rand_range(1, 19)
		yLoc = rand_range(1, 14)
	var o = MouseFollowingSquare.new(xLoc * 32 + 2 , yLoc * 32 + 2)
	return o
	
func spawnSquares(num, grid):
	var res = []
	for i in range(num):
		res.append(spawnSquare(grid))
	return res

func getHeat(resistance):
	return (50 * log(resistance + 5) - 50)

func drawGrid(obj, grid, counter):
	for x in range(grid.width):
		for y in range(grid.height):
			if(grid.getType(x, y) == Globals.get('Global/GRASS_BLOCK')):
				pass
			elif(grid.getType(x, y) == Globals.get('Global/WALL_BLOCK')):
				draw_rect(Rect2(x * 32, y * 32, 32, 32), WALL_COLOR)
						
	for x in range(grid.width):
		for y in range(grid.height):
			if grid.isUpdated(obj, x, y, counter) and grid.getDistanceValue(obj, x, y) >= 0:
				var opacity = int(255 - getHeat(grid.getDistanceValue(obj, x, y)))
				if opacity > 255:
					opacity = 255
				elif opacity < 0:
					opacity = 0
				
				draw_rect(Rect2(x * 32, y * 32, 32, 32), Color(1, 0, 0,opacity/255.0)) #(x * 32, y * 32
				draw_string(font, Vector2(x * 32, (y * 32) + 16),str(int(grid.getDistanceValue(obj, x, y))))
				#var label = render(str(int(grid.getDistanceValue(obj, x, y))), 1, Color(255,255,0))
				#blit(label, Vector2(x * 32, y * 32))
				
#var transSurface = pygame.Surface((32, 32))
#func drawTransparentRect(xLoc, yLoc, red, green, blue, opacity): # Draws a 32x32 square of the specified color and opacity
	#transSurface.set_alpha(opacity)
	#transSurface.fill((red, green, blue))
	#screen.blit(transSurface, (xLoc, yLoc))


func _ready():
	randomize()
	mGrid = Grid.new(20, 15)
	mouse = Objective.new(30)
	mouse.x = 10
	mouse.y = 7
	pathFind = true
	magic = WFEASearch.new(mGrid, [mouse])
	stalkerSquares = spawnSquares(50, mGrid)
	counter = 0
	mGrid.addObjective(mouse)
	set_process_input(true)
	set_process(true)

func _draw():
	magic.updateObjectivesPF(counter)
	drawGrid(mouse, mGrid, counter)
	var toResp = []
	if pathFind:
		for sqInd in range(stalkerSquares.size()):
			var square = stalkerSquares[sqInd]
			square.update(magic, mouse, mGrid, counter)
			draw_rect(Rect2(square.x, square.y, 16, 16), SQUARE_COLOR)
			var xBlock = int(square.x / 32)
			var yBlock = int(square.y / 32)
			if mGrid.getPassingValue(xBlock, yBlock) < 0 or (xBlock == mouse.x and yBlock == mouse.y):
				toResp.append(sqInd)
				continue
		for sqInd in toResp:
			stalkerSquares[sqInd] = spawnSquare(mGrid)
	counter = counter + 1


func _process(delta):
	update()
	
func _input(event):
	if event.type == InputEvent.MOUSE_MOTION:
		temp = get_global_mouse_pos()
		mouse.x = int(temp.x / 32)
		mouse.y = int(temp.y / 32)
		var currentType = mGrid.getType(mouse.x, mouse.y)