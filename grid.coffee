Grid = angular.module('Grid', [])

mainController = ($scope, $http) ->
  $scope.n = 4
  $scope.states = []
  $scope.transpos = []
  $scope.rects = []

  #console.log $scope.states

arrayExcept = (arr, i) ->
  result = arr[0..]
  result.splice(i, 1)
  result

permute = (arr) ->
  arr = Array::slice.call arr, 0
  return [[]] if arr.length == 0
  permutations = (for value, i in arr
    [value].concat perm for perm in permute arrayExcept arr, i)
  [].concat permutations...

# cache to store permutations so we don't keep generating them redundantly
states = []
transpos = []
rects = []

indTranspo = (n, t) -> t[0]*(2*n-3-t[0])/2-1+t[1]

# assume O and X permutations are valid by the time we feed them into the
# function, so have to validate before feeding
grid = (oxPerms) ->

  [oPerm, xPerm] = oxPerms

  # grid size
  n = oPerm.length

  # initialize things in cache if it's not already there
  unless states[n]?

    # initialize states[n]
    states[n] = permute [1..n]

    # initialize transpos[n]
    transpos[n] = []
    for i in [0...n]
      for j in [i + 1...n]
        transpos[n].push [i, j]

    # initialize rects[n]
    rects[n] = []
    for state, stateInd in states[n]
      rects[n][stateInd] = []
      for i in [0...n]
        for j in [i + 1...n]
          # technically we have to shift the y-coordinates of everything down
          # by 1, but pretty sure the algorithm is still correct because only
          # need relative coordinates to check containment
          v1 = [i, state[i]]
          v2 = [j, state[j]]
          if hasNone(v1, v2, ([k, state[k]] for k in [i + 1...j] by 1))
            rects[n][stateInd].push(indTranspo(n, [i, j]))
          if hasNone(v2, v1, ([k, state[k]] for k in [0...i].concat [j + 1...n] by 1))
            rects[n][stateInd].push(indTranspo(n, [i, j]) + n*(n-1)/2)

  # define coordinates (in R^2) for O's and X's
  oPoints = ([i + .5, y - .5] for y, i in oPerm)
  xPoints = ([i + .5, y - .5] for y, i in xPerm)

  col = 3
  computables = [
    name: "d"
    none: xPoints
    all: []
   ,
    name: "Hx"
    none: arrayExcept(xPoints, col - 1)
    all: [xPoints[col - 1]]
   ,
    name: "Ho"
    none: xPoints
    all: [oPoints[col - 1]]
   ,
    name: "Hxo"
    none: arrayExcept(xPoints, col - 1)
    all: [xPoints[col - 1], oPoints[col - 1]]
  ]
  computable.result = [] for computable in computables

  grading = []

  for state, stateInd in states[n]

    # define coordinates (in R^2) for state
    statePoints = ([i, y - 1] for y, i in state)

    # compute Maslov and Alexander gradings of state
    mo = eye(statePoints, statePoints) - eye(statePoints, oPoints) - eye(oPoints, statePoints) + eye(oPoints, oPoints) + 1
    mx = eye(statePoints, statePoints) - eye(statePoints, xPoints) - eye(xPoints, statePoints) + eye(xPoints, xPoints) + 1
    alex = (mo - mx - n + 1) / 2
    grading[stateInd] = [mo, alex]
    console.log "[#{state.join('')}]: M = #{mo}, A = #{alex}"

    computable.result[stateInd] ?= [] for computable in computables

    for rect in rects[n][stateInd]
      nchoose2 = n*(n-1)/2
      transpoInd = rect % nchoose2
      transpo = transpos[n][transpoInd]

      v1 = statePoints[transpo[0]]
      v2 = statePoints[transpo[1]]

      for computable in computables
        computable.result[stateInd][transpoInd] ?= []
        if rect < nchoose2
          if hasNone(v1, v2, computable.none) and hasAll(v1, v2, computable.all)
            computable.result[stateInd][transpoInd][0] = pretty xoCount(v1, v2, oPoints)
        else
          if hasNone(v2, v1, computable.none) and hasAll(v2, v1, computable.all)
            computable.result[stateInd][transpoInd][1] = pretty xoCount(v2, v1, oPoints)

  for computable in computables
    display(n, computable.name, computable.result)

display = (n, name, thing) ->
  for i in [0...thing.length]
    answer = []
    for j in [0...thing[i].length]
      transpoStr = transpose(states[n][i], transpos[n][j])
      if thing[i][j]?
        transpo = thing[i][j]
        if transpo[0] is undefined
          if transpo[1] isnt undefined
            answer.push((if transpo[1] is "1" then "" else transpo[1]) + transpoStr)
        else
          if transpo[1] is undefined
            answer.push((if transpo[0] is "1" then "" else transpo[0]) + transpoStr)
          else
            answer.push "(#{transpo[0]}+#{transpo[1]})#{transpoStr}"
    console.log "#{name}#{prettyPerm states[n][i]} = #{answer.join(' + ')}"

transpose = (state, transpo) ->
  temp = state[0..]
  dummy = temp[transpo[0]]
  temp[transpo[0]] = temp[transpo[1]]
  temp[transpo[1]] = dummy
  prettyPerm(temp)

prettyPerm = (state) ->
  if state.length < 10 then "[#{state.join('')}]" else JSON.stringify(state)

isBetween = (a, b, c) -> a < b and b < c
isntBetween = (a, b, c) -> b < a or b > c

inRect = (sw, ne, p) ->
  if sw[0] < ne[0]
    if sw[1] < ne[1]
      isBetween(sw[0], p[0], ne[0]) and isBetween(sw[1], p[1], ne[1])
    else
      isBetween(sw[0], p[0], ne[0]) and isntBetween(ne[1], p[1], sw[1])
  else
    if sw[1] < ne[1]
      isntBetween(ne[0], p[0], sw[0]) and isBetween(sw[1], p[1], ne[1])
    else
      isntBetween(ne[0], p[0], sw[0]) and isntBetween(ne[1], p[1], sw[1])

eye = (aPoints, bPoints) ->
  counter = 0
  for a in aPoints
    for b in bPoints
      counter += 1 if a[0] < b[0] and a[1] < b[1]
  counter

xoCount = (sw, ne, points) -> # points should be xPoints or oPoints
  result = []
  result.push(inRect(sw, ne, p)) for p in points
  result

hasAll = (sw, ne, points) ->
  for point in points
    return false unless inRect(sw, ne, point)
  return true

hasNone = (sw, ne, points) ->
  for point in points
    return false if inRect(sw, ne, point)
  return true

pretty = (xoCountResult) ->
  result = ""
  for contains, i in xoCountResult
    result += "V#{i+1}" if contains
  result = "1" if result is ""
  result

oxLib =
  unknot: [[1,2],[2,1]]
  torus: (p,q) -> [[p+q..1], [p..1].concat [p+q..p+1]]

  # ox = 0(O) or 1(X); mnemonic: 0 is O
  # dir = 1(NE), 2(NW), 3(SW), 4(SE); mnemonic: quadrants
  # i = # of column of O/X to be stabilized
  # perms = [oPerm, xPerm]
  # don't try to understand this, it's very cryptic and I'm not even sure it's optimized lol
  stab: (ox, dir, i, perms) ->
    result = []
    height = perms[ox][i - 1]
    result[ox] = ((if j > height then j + 1 else j) for j in perms[ox])
    result[ox].splice((if dir % 2 then i - 1 else i), 0, height + 1)
    height += 1 if dir > 2
    result[1 - ox] = ((if j >= height then j + 1 else j) for j in perms[1 - ox])
    result[1 - ox].splice((if isBetween(1, dir, 4) then i else i - 1), 0, height)
    result

#grid([1,3,2], [2,1,3])
#grid([2,1,6,5,4,3], [5,4,3,6,2,1])
#grid [[2,1,4,3],[1,4,3,2]]
grid [[2,1,3,4],[1,4,2,3]]
#grid [[2,1,3],[1,3,2]]

#console.log oxLib.stab(0,3,2,oxLib.unknot)
#console.log oxLib.stab(1,2,2,[[1,3,2],[2,1,3]])
#console.log oxLib.unknot
