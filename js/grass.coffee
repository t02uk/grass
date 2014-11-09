__DEBUG__ = false
pass = undefined

class God
  @setup: ->
    @deviceWidth = 640.0
    @deviceHeight = 480.0
    @scene = new THREE.Scene()
    @scene.fog = new THREE.FogExp2(0x000000, 0.03)
    @camera = new THREE.PerspectiveCamera(90, @deviceWidth / @deviceHeight, Math.pow(0.1, 8), Math.pow(10, 3))
    @renderer = new THREE.WebGLRenderer(antialias: true)
    @renderer.setSize(@deviceWidth, @deviceHeight)
    @renderer.setClearColor(0x444499, 0)
    c = document.getElementById('c')
    c.appendChild(@renderer.domElement)

    @grasses = for i in [0...500]
      new Grass(@scene)

    @particles = new Particles(@scene)

  @start: ->
    startTime = +new Date()
    render = =>
      @tick = new Date() - startTime
      for grass in @grasses
        grass.update()
      @camera.position.z = Math.sin(@tick * 0.0005) * 5
      @camera.position.y = Math.sin(@tick * 0.0005) * 2 + 2.0
      @camera.position.x = Math.cos(@tick * 0.0005) * 5
      @camera.lookAt(new THREE.Vector3(0, 3, 0))
      requestAnimationFrame(render)
      @renderer.render(@scene, @camera)
      @particles.update()
    render()

class Grass
  class Bone
    constructor: (@index, p) ->
      @position = new THREE.Vector3()

  constructor: (@scene) ->

    m = 12
    r = Math.cos(Math.random() * 1.55) * 15
    th = Math.random() * 100
    @position = new THREE.Vector3(r * Math.sin(th), 0, r * Math.cos(th))
    @bones = for index in [0 ... m]
      new Bone(index, @position)
    @height = Math.random() * 0.2 + 0.1

    @geometry = new THREE.Geometry()
    for v, i in @bones
      @geometry.vertices.push(
        new THREE.Vector3(-1, i, 0),
        new THREE.Vector3( 1, i, 0)
      )
    for i in [0 ... m - 1]
      vi = i * 2
      @geometry.faces.push(
        new THREE.Face3(vi    , vi + 1, vi + 2),
        new THREE.Face3(vi + 1, vi + 3, vi + 2)
      )
      @geometry.faceVertexUvs[0].push([
        new THREE.Vector2(1.0, 0.0),
        new THREE.Vector2(0.0, 0.0),
        new THREE.Vector2(1.0, 1.0)
        ], [
        new THREE.Vector2(0.0, 0.0),
        new THREE.Vector2(0.0, 1.0),
        new THREE.Vector2(1.0, 1.0)
      ])

    color = new THREE.Color()
    @material = new THREE.MeshBasicMaterial
      color: color
      map: @makeTexture()
      side: THREE.DoubleSide
      blending: THREE.AdditiveBlending
      transparent: true
      depthTest: false
    @mesh = new THREE.Mesh(@geometry, @material)
    @scene.add(@mesh)

  makeTexture: ->
    unless Grass.texture
      @canvas = document.createElement('canvas')
      width = @canvas.width = 128
      height = @canvas.height = 128
      ctx = @canvas.getContext('2d')
      grad = ctx.createLinearGradient(0, 0, width, 0)
      grad.addColorStop(0, 'rgb(0, 0, 0)')
      grad.addColorStop(0.39, 'rgb(32, 64, 32)')
      grad.addColorStop(0.4, 'rgb(192, 255, 192)')
      grad.addColorStop(0.5, 'rgb(160, 160, 160)')
      grad.addColorStop(0.6, 'rgb(192, 255, 192)')
      grad.addColorStop(0.61, 'rgb(32, 64, 32)')
      grad.addColorStop(1, 'rgb(0, 0, 0)')
      ctx.fillStyle = grad
      ctx.beginPath()
      ctx.rect(0, 0, width, height)
      ctx.fill()
      Grass.texture = THREE.ImageUtils.loadTexture(@canvas.toDataURL())
      document.body.appendChild(@canvas) if __DEBUG__
    Grass.texture

  update: ->
    k = @height
    y = 0
    t = 0
    for bone, i in @bones
      k *= 0.98
      bone.position.set(0, Math.cos(t) * y, Math.sin(t) * y)
      t += Math.sin(God.tick * 0.001 + y * 0.1 + (@position.x + @position.z) * 0.01) * 0.03 + 0.005
      y += k

    for bone in @bones
      i = bone.index
      p = bone.position
      s = new THREE.Vector3(@height * 3, 0, 0)
      w = Math.cos(1.0 * i / @bones.length * Math.PI / 2) * 0.1
      s.multiplyScalar(w)
      @geometry.vertices[i * 2 + 0].set(p.x + s.x + @position.x, p.y + s.y + @position.y, p.z + s.z + @position.z)
      @geometry.vertices[i * 2 + 1].set(p.x - s.x + @position.x, p.y - s.y + @position.y, p.z - s.z + @position.z)

    @geometry.verticesNeedUpdate = true

class Particles
  TYPE =
    tp1: 500
    tp2: 1000
    tp3: 1500
    numTypes: 3

    to: (index) ->
      if index < 0
        0
      else if index < TYPE.tp1
        TYPE.tp1
      else if index < TYPE.tp2
        TYPE.tp2
      else if index < TYPE.tp3
        TYPE.tp3
      else
        TYPE.maxIndex
    ind: (index) ->
      if index is 0
        TYPE.tp1
      else if index is 1
        TYPE.tp2
      else if index is 2
        TYPE.tp3
      else
        0
    size: (index) ->
      if index is 0
        TYPE.tp1 - 0
      else if index is 1
        TYPE.tp2 - TYPE.tp1
      else if index is 2
        TYPE.tp3 - TYPE.tp2
    maxIndex: 1500

  constructor: (@scene) ->
    
    @geometries = []

    for tp in [0...TYPE.numTypes]
      geometry = new THREE.Geometry()
      for i in [0...TYPE.size(tp)]
        r = Math.cos(Math.random() * 1.4) * 20
        th = Math.random() * 100
        vertex = new THREE.Vector3(Math.sin(th) * r, 0, Math.cos(th) * r)
        geometry.vertices.push(vertex)
      @geometries.push(geometry)
      console.info(geometry.vertices.length)

    for i in [0...TYPE.numTypes]
      material = if TYPE.ind(i) is TYPE.tp1
        new THREE.PointCloudMaterial
          size: 1.0
          map: @makeTexture(TYPE.tp1)
          blending: THREE.AdditiveBlending
          transparent: true
          depthTest: false

      else if TYPE.ind(i) is TYPE.tp2
        new THREE.PointCloudMaterial
          size: 4.0
          map: @makeTexture(TYPE.tp2)
          blending: THREE.AdditiveBlending
          transparent: true
          depthTest: false

      else if TYPE.ind(i) is TYPE.tp3
        new THREE.PointCloudMaterial
          size: 10.0
          map: @makeTexture(TYPE.tp3)
          blending: THREE.AdditiveBlending
          transparent: true
          depthTest: false

      mesh = new THREE.PointCloud(@geometries[i], material)
      @scene.add(mesh)

  
  makeTexture: (tp) ->
    canvas = document.createElement('canvas')
    width = canvas.width = 256
    height = canvas.height = 256
    ctx = canvas.getContext('2d')

    if tp is TYPE.tp1
      grad = ctx.createRadialGradient(width / 2, height / 2, width / 4, width / 2, height / 2, width / 2)
      grad.addColorStop(0, 'rgb(160, 255, 255)')
      grad.addColorStop(0.10, 'rgb(96, 128, 128)')
      grad.addColorStop(0.60, 'rgb(48, 48, 32)')
      grad.addColorStop(1, 'rgb(0, 0, 0)')
    else if tp is TYPE.tp2
      grad = ctx.createRadialGradient(width / 2, height / 2, 0, width / 2, height / 2, width / 2)
      grad.addColorStop(0, 'rgb(32, 32, 32)')
      grad.addColorStop(1, 'rgb(0, 0, 0)')
    else if tp is TYPE.tp3
      grad = ctx.createRadialGradient(width / 2, height / 2, 0, width / 2, height / 2, width / 2)
      grad.addColorStop(0, 'rgb(8, 8, 16)')
      grad.addColorStop(1, 'rgb(0, 0, 0)')

    ctx.fillStyle = grad
    ctx.beginPath()
    ctx.rect(0, 0, width, height)
    ctx.fill()
    document.body.appendChild(canvas) if __DEBUG__
    texture = THREE.ImageUtils.loadTexture(canvas.toDataURL())
    texture

  update: ->
    u = 0
    for geometry, tp in @geometries
      for vertex, i in geometry.vertices
        u++
        if TYPE.ind(tp) is TYPE.tp1
          th = God.tick * 0.0005 + i
          vertex.x += Math.sin(God.tick * 0.0005 + i) * 0.02
          vertex.z += Math.cos(God.tick * 0.0005 + i * 2) * 0.02
          vertex.y = Math.sin(th) * 20
          if Math.cos(th) < 0
            vertex.y *= -1
          if vertex.y < 0
            vertex.y += 20
        else if TYPE.ind(tp) is TYPE.tp2
          God.grasses[i].position.copy(vertex)
        else if TYPE.ind(tp) is TYPE.tp3
          th = God.tick * 0.001 + i
          vertex.y = Math.sin(th) * 2 + 4

      geometry.verticesNeedUpdate = true
window.God = God
