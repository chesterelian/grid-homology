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

xPerm = [1,4,3,2]
oPerm = [2,1,4,3]

# grid size
n = xPerm.length

states = permute [1..n]
#console.log states

# define coordinates (in R^2) for X's and O's
xs = ([i + .5, y - .5] for y, i in xPerm)
os = ([i + .5, y - .5] for y, i in oPerm)

eye = (aPoints, bPoints) ->
  counter = 0
  for a in aPoints
    for b in bPoints
      counter += 1 if a[0] < b[0] and a[1] < b[1]
  counter

countOs = (x1, y1, x2, y2) ->

  result = (0 for i in [1..n])

  if x1 < x2 and y1 < y2
    for point, i in os
      if x1 < point[0] and point[0] < x2 and y1 < point[1] and point[1] < y2
        result[i] += 1

  if x1 < x2 and y1 > y2
    for point, i in os
      if x1 < point[0] and point[0] < x2 and not(y2 < point[1] and point[1] < y1)
        result[i] += 1

  if x1 > x2 and y1 < y2
    for point, i in os
      if not(x2 < point[0] and point[0] < x1) and y1 < point[1] and point[1] < y2
        result[i] += 1

  if x1 > x2 and y1 > y2
    for point, i in os
      if not(x2 < point[0] and point[0] < x1) and not(y2 < point[1] and point[1] < y1)
        result[i] += 1

  #console.log "oCount for #{x1}, #{y1}, #{x2}, #{y2}: #{JSON.stringify(result)}"
  result

isEmpty = (x1, y1, x2, y2, what) ->

  if x1 < x2 and y1 < y2
    for point in what
      if x1 < point[0] and point[0] < x2 and y1 < point[1] and point[1] < y2
        return false

  if x1 < x2 and y1 > y2
    for point in what
      if x1 < point[0] and point[0] < x2 and not(y2 <= point[1] and point[1] <= y1)
        return false

  if x1 > x2 and y1 < y2
    for point in what
      if not(x2 <= point[0] and point[0] <= x1) and y1 < point[1] and point[1] < y2
        return false

  if x1 > x2 and y1 > y2
    for point in what
      if not(x2 <= point[0] and point[0] <= x1) and not(y2 <= point[1] and point[1] <= y1)
        return false

  return true

for state in states

  # define coordinates (in R^2) for state
  ss = ([i, y - 1] for y, i in state)

  # compute Maslov and Alexander gradings of state
  mo = eye(ss,ss) - eye(ss,os) - eye(os,ss) + eye(os,os) + 1
  mx = eye(ss,ss) - eye(ss,xs) - eye(xs,ss) + eye(xs,xs) + 1
  alex = (mo - mx - xPerm.length + 1) / 2
  console.log "[#{state}]: M = #{mo}, A = #{alex}"

pretty = (oCount) ->
  result = ""
  for count, i in oCount
    if count != 0
      result += "V#{i+1}"
  if result is ""
    result = "1"
  result

homstr = []
hom2str = []
# compute tilde differential with mod 2 coefficients
for state in states

  ss = ([i, y - 1] for y, i in state)

  # d(state)
  diff = []
  # H(state)
  homotopy = []
  homotopy2 = []

  #console.log "current state is #{state} with coordinates #{JSON.stringify(ss)}"

  # run through all transpositions
  for ii in [0...n]
    for jj in [ii+1...n]
      x1 = ss[ii][0]
      y1 = ss[ii][1]
      x2 = ss[jj][0]
      y2 = ss[jj][1]

      #console.log "current transposition is [#{ii+1},#{jj+1}] with coordinates #{x1}, #{y1}, #{x2}, #{y2}"

      coeff = []
      coeffH = []
      coeffH2 = []

      # rectangle with (x1,y1) as lower left
      #console.log "current rectangle is [#{x1},#{y1}] to [#{x2},#{y2}]"
      #coeff += 1 if isEmpty(x1, y1, x2, y2, [xs..., os..., ss...])
      if isEmpty(x1, y1, x2, y2, [xs..., ss...])
        coeff.push(pretty countOs(x1, y1, x2, y2))
      # rectangle with (x2,y2) as lower left
      #console.log "current rectangle is [#{x2},#{y2}] to [#{x1},#{y1}]"
      #coeff += 1 if isEmpty(x2, y2, x1, y1, [xs..., os..., ss...])
      if isEmpty(x2, y2, x1, y1, [xs..., ss...])
        coeff.push(pretty countOs(x2, y2, x1, y1))

      k = 2
      if isEmpty(x1, y1, x2, y2, arrayExcept(xs, k).concat(ss)) and not(isEmpty(x1, y1, x2, y2, [xs[k]]))
        coeffH.push(pretty countOs(x1, y1, x2, y2))
      if isEmpty(x2, y2, x1, y1, arrayExcept(xs, k).concat(ss)) and not(isEmpty(x2, y2, x1, y1, [xs[k]]))
        coeffH.push(pretty countOs(x2, y2, x1, y1))

      if isEmpty(x1, y1, x2, y2, xs.concat(ss)) and not(isEmpty(x1, y1, x2, y2, [os[k]]))
        coeffH2.push(pretty countOs(x1, y1, x2, y2))
      if isEmpty(x2, y2, x1, y1, xs.concat(ss)) and not(isEmpty(x2, y2, x1, y1, [os[k]]))
        coeffH2.push(pretty countOs(x2, y2, x1, y1))

      #console.log "coeff is #{coeff}"

      #if coeff % 2 == 1
      if coeff.length > 0
        dum = state[0..]
        temp = dum[ii]
        dum[ii] = dum[jj]
        dum[jj] = temp
        str = coeff.join("+")
        if coeff.length > 1
          str = "(#{str})"
        if str is "1"
          str = ""
        diff.push(str + JSON.stringify(dum))

      if coeffH.length > 0
        dum = state[0..]
        temp = dum[ii]
        dum[ii] = dum[jj]
        dum[jj] = temp
        str = coeffH.join("+")
        if coeffH.length > 1
          str = "(#{str})"
        if str is "1"
          str = ""
        homotopy.push(str + JSON.stringify(dum))

      if coeffH2.length > 0
        dum = state[0..]
        temp = dum[ii]
        dum[ii] = dum[jj]
        dum[jj] = temp
        str = coeffH2.join("+")
        if coeffH2.length > 1
          str = "(#{str})"
        if str is "1"
          str = ""
        homotopy2.push(str + JSON.stringify(dum))

  console.log("d[#{state}] = " + diff.join(" + "))# if diff.length is 0
  homstr.push("H[#{state}] = " + homotopy.join(" + "))# if homotopy.length is 0
  hom2str.push("H2[#{state}] = " + homotopy2.join(" + "))# if homotopy.length is 0

console.log str for str in homstr
console.log str for str in hom2str
