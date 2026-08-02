//
//  ContentView.swift
//  Halloween Haunts
//
//  Created by Elliot Williams on 2025-06-20.
//

import SwiftUI
import Combine

struct HalloweenGame: View {
    @StateObject private var game = GameEngine()
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Game canvas
                Canvas { context, size in
                    game.size = size
                    game.update()
                    game.draw(context: &context)
                }
                .background(Color.orange)
                .gesture(
                    TapGesture()
                        .onEnded { _ in
                            game.handleTap()
                        }
                )
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            game.handleDrag(value.location)
                        }
                )
                
                // Score display
                VStack {
                    HStack {
                        Text("Score: \(game.sc)")
                            .font(.title)
                            .padding()
                            .background(Color.white.opacity(0.6))
                            .cornerRadius(10)
                            .padding(.top, 20)
                        
                        Spacer()
                        
                        Text("Level: \(game.l)")
                            .font(.title)
                            .padding()
                            .background(Color.white.opacity(0.6))
                            .cornerRadius(10)
                            .padding(.top, 20)
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                }
                
                // Start screen
                if game.intro {
                    VStack {
                        Text("Halloween Game")
                            .font(.largeTitle)
                            .bold()
                            .foregroundColor(.black)
                            .padding()
                            .background(Color.orange)
                            .cornerRadius(10)
                        
                        Text("Tap to Start")
                            .font(.title)
                            .foregroundColor(.black)
                            .padding()
                            .background(Color.orange)
                            .cornerRadius(10)
                            .padding(.top, 20)
                    }
                    .transition(.scale)
                }
                
                // Game over screen
                if game.end && !game.intro {
                    VStack {
                        Text("Game Over")
                            .font(.largeTitle)
                            .bold()
                            .foregroundColor(.black)
                            .padding()
                            .background(Color.orange)
                            .cornerRadius(10)
                        
                        Text("Highest Score: \(game.hs)")
                            .font(.title)
                            .foregroundColor(.black)
                            .padding()
                            .background(Color.orange)
                            .cornerRadius(10)
                            .padding(.top, 20)
                        
                        Text("Tap to Try Again")
                            .font(.title)
                            .foregroundColor(.black)
                            .padding()
                            .background(Color.orange)
                            .cornerRadius(10)
                            .padding(.top, 20)
                    }
                    .transition(.opacity)
                }
            }
            .onAppear {
                game.setup(size: geometry.size)
                game.startTimer()
            }
            .onChange(of: geometry.size) { newSize in
                game.setup(size: newSize)
            }
            .onReceive(game.timer) { _ in
                if !game.intro && !game.end {
                    game.time += 1
                    if game.time >= 300 { game.time = 0 }
                }
            }
            .onDisappear {
                game.stopTimer()
            }
        }
        .edgesIgnoringSafeArea(.all)
    }
}

// MARK: - Game Engine
class GameEngine: ObservableObject {
    // Game state
    @Published var sc = 0
    @Published var l = 1
    @Published var hs = 0
    @Published var end = false
    @Published var intro = true
    @Published var time = 0
    
    let frameRate = 1/60
    
    // Game objects
    var bk = Basket()
    var eggs: [Egg] = []
    var sgs: [SG] = []
    var ggs: [GG] = []
    var lgs: [LG] = []
    var cgs: [CG] = []
    var witches: [Witch] = []
    var bn = Bunny()
    
    // Game properties
    var size = CGSize.zero
    var bodyX: CGFloat = 200
    var bodyY: CGFloat = 0
    var batPositions: [CGFloat] = [0, 0, 0, 0, 0, 0]
    var batSpeeds: [CGFloat] = [7, 8, 9, 9.5, 8.5, 7.5]
    var owlPosition = CGPoint(x: 200, y: 200)
    var owlDirection = CGPoint(x: 1, y: 1)
    var owlSpeed: CGFloat = 3
    
    // Timer for game loop
    var timer = Timer.publish(every: 1/60, on: .main, in: .common).autoconnect()
    var timerCancellable: AnyCancellable?
    
    func startTimer() {
        timerCancellable = timer.sink { _ in
            self.time += 1
            if self.time >= 300 { self.time = 0 }
        }
    }
    
    func stopTimer() {
        timerCancellable?.cancel()
    }
    
    func resetGame() {
        // Reset game state
        time = 0
        l = 1
        
        // Reset bunny
        bn = Bunny()
        
        // Reset eggs positions
        for i in eggs.indices {
            eggs[i].y = CGFloat.random(in: -800..<0)
            eggs[i].x = CGFloat.random(in: 0..<size.width)
        }
        
        // Reset witches
        for i in witches.indices {
            witches[i].x = CGFloat.random(in: 0..<size.width)
            witches[i].y = CGFloat.random(in: 0..<size.height/2)
        }
        
        // Reset bat positions
        batPositions = [0, 0, 0, 0, 0, 0]
        
        // Reset body position
        bodyY = 0
    }
    
    func setup(size: CGSize) {
        self.size = size
        
        // Initialize witches
        witches = (0..<5).map { _ in
            Witch(
                x: CGFloat.random(in: 0..<size.width),
                y: CGFloat.random(in: 0..<size.height/2),
                color: Color(
                    red: Double.random(in: 0...1),
                    green: Double.random(in: 0...1),
                    blue: Double.random(in: 0...1)
                ),
                velX: CGFloat.random(in: -2...2),
                velY: CGFloat.random(in: -2...2),
                accX: CGFloat.random(in: 0...0.5),
                accY: CGFloat.random(in: 0...0.05),
                random: Int.random(in: 0..<4)
            )
        }
        
        // Initialize eggs
        eggs = (0..<20).map { _ in
            Egg(
                color: Color(
                    red: Double.random(in: 0...1),
                    green: Double.random(in: 0...1),
                    blue: Double.random(in: 0...1),
                    opacity: Double.random(in: 0.5...1)
                ),
                x: CGFloat.random(in: 0..<size.width),
                y: CGFloat.random(in: -800..<0),
                size: CGFloat.random(in: 0.1...1)
            )
        }
        
        // Initialize other objects
        sgs = (0..<20).map { _ in SG() }
        ggs = (0..<20).map { _ in GG() }
        lgs = (0..<20).map { _ in LG() }
        cgs = (0..<20).map { _ in CG() }
        
        // Set initial basket position
        bk.bx = size.width / 2
        bk.by = size.height - 100
    }
    
    func update() {
        // Update falling objects
        for index in eggs.indices {
            eggs[index].move(size: size)
            if bk.intersects(egg: eggs[index]) {
                eggs[index].caught()
                sc += 3
            }
        }
        
        // Update witches
        for i in 0..<witches.count {
            witches[i].update(size: size)
            witches[i].checkEdges(size: size)
        }
        
        // Update bat positions
        for i in 0..<batPositions.count {
            batPositions[i] += batSpeeds[i]
            if batPositions[i] > size.width {
                batPositions[i] = -50
            }
        }
        
        // Update owl position
        owlPosition.x += owlDirection.x * owlSpeed
        owlPosition.y += owlDirection.y * owlSpeed
        
        if owlPosition.x > size.width || owlPosition.x < 0 {
            owlDirection.x *= -1
        }
        if owlPosition.y > size.height || owlPosition.y < 0 {
            owlDirection.y *= -1
        }
        
        // Update body position
        bodyY += 1
        if bodyY > 340 {
            bodyY = -40
        }
        
        // Update levels
        if sc > 10 && sc <= 50 {
            l = 2
        } else if sc > 50 && sc <= 110 {
            l = 3
        } else if sc > 110 && sc <= 179 {
            l = 4
        } else if sc > 179 {
            l = 5
        }
        
        // Check game over conditions (example: if score reaches certain threshold or time limit)
        // You can add your own game over logic here
        if sc > 0 && sc % 200 == 0 {
            end = true
            if sc > hs {
                hs = sc
            }
        }
        
        // Update bunny
        bn.move(size: size)
        
        // Constrain basket position
        bk.bx = max(50, min(bk.bx, size.width - 50))
        bk.by = max(50, min(bk.by, size.height - 100))
    }
    
    func draw(context: inout GraphicsContext) {
        // Draw background elements
        drawVillage(context: &context)
        
        // Draw bats
        for i in 0..<batPositions.count {
            drawBat(
                context: &context,
                position: CGPoint(x: batPositions[i], y: 50 + CGFloat(i) * 70),
                size: 25
            )
        }
        
        // Draw owl
        drawOwl(context: &context, position: owlPosition)
        
        // Draw pumpkins
        drawPumpkin(context: &context, position: CGPoint(x: 230, y: size.height - 30))
        drawPumpkin(context: &context, position: CGPoint(x: 740, y: size.height - 30))
        drawPumpkin(context: &context, position: CGPoint(x: 1220, y: size.height - 30))
        
        // Draw body
        drawBody(context: &context, position: CGPoint(x: bodyX, y: bodyY))
        
        // Draw game objects
        for egg in eggs {
            egg.draw(context: &context)
        }
        
        for witch in witches {
            witch.draw(context: &context)
        }
        
        // Draw basket
        bk.draw(context: &context)
        
        // Draw bunny
        if sc > 20 {
            bn.draw(context: &context)
        }
    }
    
    func handleTap() {
        if intro {
            intro = false
            end = false
            sc = 0
            resetGame()
        } else if end && !intro {
            end = false
            sc = 0
            resetGame()
        }
    }
    
    func handleDrag(_ location: CGPoint) {
        bk.setPosition(location)
    }
    
    // MARK: - Drawing Functions
    
    func drawBat(context: inout GraphicsContext, position: CGPoint, size: CGFloat) {
        // Body
        var body = Path()
        body.addEllipse(in: CGRect(x: position.x - size/2, y: position.y - size/2, width: size, height: size))
        context.fill(body, with: .color(.black))
        
        // Wings
        var leftWing = Path()
        leftWing.move(to: CGPoint(x: position.x - size * 1.5, y: position.y))
        leftWing.addQuadCurve(
            to: CGPoint(x: position.x - size * 3, y: position.y - size/2.5),
            control: CGPoint(x: position.x - size * 2, y: position.y - size)
        )
        leftWing.addQuadCurve(
            to: CGPoint(x: position.x - size * 1.5, y: position.y),
            control: CGPoint(x: position.x - size * 2, y: position.y - size/3)
        )
        context.fill(leftWing, with: .color(.black))
        
        var rightWing = Path()
        rightWing.move(to: CGPoint(x: position.x + size * 1.5, y: position.y))
        rightWing.addQuadCurve(
            to: CGPoint(x: position.x + size * 3, y: position.y - size/2.5),
            control: CGPoint(x: position.x + size * 2, y: position.y - size)
        )
        rightWing.addQuadCurve(
            to: CGPoint(x: position.x + size * 1.5, y: position.y),
            control: CGPoint(x: position.x + size * 2, y: position.y - size/3)
        )
        context.fill(rightWing, with: .color(.black))
        
        // Eyes
        var leftEye = Path()
        leftEye.addEllipse(in: CGRect(
            x: position.x - size/5 - size/6,
            y: position.y - size/6,
            width: size/3,
            height: size/3
        ))
        context.fill(leftEye, with: .color(.yellow))
        
        var leftPupil = Path()
        leftPupil.addEllipse(in: CGRect(
            x: position.x - size/5 - size/12,
            y: position.y - size/12,
            width: size/10,
            height: size/10
        ))
        context.fill(leftPupil, with: .color(.black))
        
        var rightEye = Path()
        rightEye.addEllipse(in: CGRect(
            x: position.x + size/5 - size/6,
            y: position.y - size/6,
            width: size/3,
            height: size/3
        ))
        context.fill(rightEye, with: .color(.yellow))
        
        var rightPupil = Path()
        rightPupil.addEllipse(in: CGRect(
            x: position.x + size/5 - size/12,
            y: position.y - size/12,
            width: size/10,
            height: size/10
        ))
        context.fill(rightPupil, with: .color(.black))
    }
    
    func drawOwl(context: inout GraphicsContext, position: CGPoint) {
        // Body
        var body = Path()
        body.addEllipse(in: CGRect(x: position.x - 35, y: position.y - 35, width: 70, height: 70))
        context.fill(body, with: .color(.gray))
        
        // Head
        var head = Path()
        head.addEllipse(in: CGRect(x: position.x - 25, y: position.y - 65, width: 50, height: 50))
        context.fill(head, with: .color(.gray))
        
        // Eyes
        var leftEye = Path()
        leftEye.addEllipse(in: CGRect(x: position.x - 20, y: position.y - 60, width: 15, height: 15))
        context.fill(leftEye, with: .color(.black))
        
        var rightEye = Path()
        rightEye.addEllipse(in: CGRect(x: position.x + 5, y: position.y - 60, width: 15, height: 15))
        context.fill(rightEye, with: .color(.black))
        
        // Beak
        var beak = Path()
        beak.move(to: CGPoint(x: position.x - 5, y: position.y - 45))
        beak.addLine(to: CGPoint(x: position.x, y: position.y - 35))
        beak.addLine(to: CGPoint(x: position.x + 5, y: position.y - 45))
        context.fill(beak, with: .color(.orange))
    }
    
    func drawPumpkin(context: inout GraphicsContext, position: CGPoint) {
        // Pumpkin body
        var pumpkin = Path()
        pumpkin.addEllipse(in: CGRect(x: position.x - 30, y: position.y - 27.5, width: 60, height: 55))
        context.fill(pumpkin, with: .color(.orange))
        
        // Stem
        var stem = Path()
        stem.move(to: CGPoint(x: position.x - 7, y: position.y - 20))
        stem.addLine(to: CGPoint(x: position.x - 7, y: position.y - 34))
        stem.addLine(to: CGPoint(x: position.x + 2, y: position.y - 34))
        stem.addLine(to: CGPoint(x: position.x + 2, y: position.y - 20))
        context.fill(stem, with: .color(.green))
        
        // Eyes
        var leftEye = Path()
        leftEye.move(to: CGPoint(x: position.x - 15, y: position.y - 5))
        leftEye.addLine(to: CGPoint(x: position.x - 10, y: position.y - 15))
        leftEye.addLine(to: CGPoint(x: position.x - 5, y: position.y - 5))
        context.fill(leftEye, with: .color(time < 150 ? .black : .yellow))
        
        var rightEye = Path()
        rightEye.move(to: CGPoint(x: position.x + 5, y: position.y - 5))
        rightEye.addLine(to: CGPoint(x: position.x + 10, y: position.y - 15))
        rightEye.addLine(to: CGPoint(x: position.x + 15, y: position.y - 5))
        context.fill(rightEye, with: .color(time < 150 ? .black : .yellow))
        
        // Mouth
        var mouth = Path()
        mouth.addEllipse(in: CGRect(x: position.x - 5, y: position.y + 5, width: 10, height: 10))
        context.fill(mouth, with: .color(.black))
    }
    
    func drawBody(context: inout GraphicsContext, position: CGPoint) {
        // Body lines
        var lines = Path()
        let offsets: [CGPoint] = [
            CGPoint(x: 25, y: 25),
            CGPoint(x: -25, y: -25),
            CGPoint(x: 25, y: -25),
            CGPoint(x: -25, y: 25),
            CGPoint(x: -30, y: -10),
            CGPoint(x: -30, y: 10),
            CGPoint(x: 30, y: 10),
            CGPoint(x: 30, y: -10)
        ]
        
        for offset in offsets {
            lines.move(to: position)
            lines.addLine(to: CGPoint(x: position.x + offset.x, y: position.y + offset.y))
        }
        context.stroke(lines, with: .color(.red), lineWidth: 1)
        
        // Body center
        var body = Path()
        body.addEllipse(in: CGRect(x: position.x - 20, y: position.y - 20, width: 40, height: 40))
        context.fill(body, with: .color(.black))
        
        var center = Path()
        center.addEllipse(in: CGRect(x: position.x - 5, y: position.y, width: 10, height: 10))
        context.fill(center, with: .color(.red))
    }
    
    func drawVillage(context: inout GraphicsContext) {
        // Ground
        var ground = Path()
        ground.addRect(CGRect(x: 0, y: size.height - 100, width: size.width, height: 100))
        context.fill(ground, with: .color(.black))
        
        // Houses
        for i in 0..<Int(size.width / 150) {
            let x = CGFloat(i) * 150
            drawHouse(context: &context, position: CGPoint(x: x + 20, y: size.height - 150))
            drawTombstone(context: &context, position: CGPoint(x: x + 70, y: size.height - 100))
        }
        
        // Moon
        var moon = Path()
        moon.addEllipse(in: CGRect(x: size.width - 150, y: 50, width: 100, height: 100))
        context.fill(moon, with: .color(.white))
    }
    
    func drawHouse(context: inout GraphicsContext, position: CGPoint) {
        // House body
        var house = Path()
        house.addRect(CGRect(x: position.x, y: position.y, width: 70, height: 60))
        context.fill(house, with: .color(.black))
        
        // Roof
        var roof = Path()
        roof.move(to: CGPoint(x: position.x - 20, y: position.y))
        roof.addLine(to: CGPoint(x: position.x + 90, y: position.y))
        roof.addLine(to: CGPoint(x: position.x + 35, y: position.y - 40))
        context.fill(roof, with: .color(.black))
        
        // Windows
        var leftWindow = Path()
        leftWindow.addRect(CGRect(x: position.x + 10, y: position.y + 10, width: 15, height: 15))
        context.fill(leftWindow, with: .color(.yellow))
        
        var rightWindow = Path()
        rightWindow.addRect(CGRect(x: position.x + 45, y: position.y + 10, width: 15, height: 15))
        context.fill(rightWindow, with: .color(.yellow))
    }
    
    func drawTombstone(context: inout GraphicsContext, position: CGPoint) {
        // Tombstone base
        var base = Path()
        base.addRect(CGRect(x: position.x, y: position.y, width: 80, height: 80))
        context.fill(base, with: .color(.gray))
        
        // Tombstone top
        var top = Path()
        top.addEllipse(in: CGRect(x: position.x + 10, y: position.y - 30, width: 60, height: 60))
        context.fill(top, with: .color(.gray))
        
        // RIP text
        let text = Text("RIP")
            .font(.system(size: 24))
            .bold()
            .foregroundColor(.black)
        context.draw(text, at: CGPoint(x: position.x + 40, y: position.y + 30))
    }
}

// MARK: - Game Objects
struct Basket {
    var bx: CGFloat = 0
    var by: CGFloat = 0
    let size: CGFloat = 60
    
    mutating func setPosition(_ position: CGPoint) {
        bx = position.x
        by = position.y
    }
    
    func intersects(egg: Egg) -> Bool {
        let basketRect = CGRect(x: bx - size/2, y: by - size/2, width: size, height: size)
        let eggRect = CGRect(x: egg.x - egg.size/2, y: egg.y - egg.size/2, width: egg.size, height: egg.size)
        return basketRect.intersects(eggRect)
    }
    
    func draw(context: inout GraphicsContext) {
        // Basket body
        var basket = Path()
        basket.addRect(CGRect(x: bx - 30, y: by - 15, width: 60, height: 30))
        context.fill(basket, with: .color(.black))
        
        // Basket handle
        var handle = Path()
        handle.move(to: CGPoint(x: bx - 40, y: by - 20))
        handle.addQuadCurve(
            to: CGPoint(x: bx + 40, y: by - 20),
            control: CGPoint(x: bx, y: by - 40)
        )
        context.stroke(handle, with: .color(.black), lineWidth: 5)
    }
}

struct Egg {
    let color: Color
    var x: CGFloat
    var y: CGFloat
    let size: CGFloat
    let speed: CGFloat = CGFloat.random(in: 1...5)
    
    mutating func move(size: CGSize) {
        y += speed
        if y > size.height {
            y = CGFloat.random(in: -800..<0)
            x = CGFloat.random(in: 0..<size.width)
        }
    }
    
    mutating func caught() {
        y = -1000
    }
    
    func draw(context: inout GraphicsContext) {
        var path = Path()
        path.addEllipse(in: CGRect(x: x - size/2, y: y - size/2, width: size, height: size))
        context.fill(path, with: .color(color))
    }
}

struct Witch {
    var x: CGFloat
    var y: CGFloat
    let color: Color
    var velX: CGFloat
    var velY: CGFloat
    let accX: CGFloat
    let accY: CGFloat
    let random: Int
    let topSpeed: CGFloat = 6
    
    mutating func update(size: CGSize) {
        velX += accX
        velY += accY
        velX = min(max(velX, -topSpeed), topSpeed)
        velY = min(max(velY, -topSpeed), topSpeed)
        x += velX
        y += velY
    }
    
    mutating func checkEdges(size: CGSize) {
        if x > size.width {
            x = 0
        } else if x < 0 {
            x = size.width
        }
        
        if y > size.height {
            velY *= -1
        } else if y < 0 {
            velY *= -1
        }
    }
    
    func draw(context: inout GraphicsContext) {
        // Hat
        var hat = Path()
        hat.move(to: CGPoint(x: x, y: y - 100))
        hat.addLine(to: CGPoint(x: x - 45, y: y + 20))
        hat.addLine(to: CGPoint(x: x, y: y))
        context.fill(hat, with: .color(.black))
        
        // Brim
        var brim = Path()
        brim.move(to: CGPoint(x: x + 5, y: y - 100))
        brim.addLine(to: CGPoint(x: x + 5, y: y - 90))
        brim.addLine(to: CGPoint(x: x + 35, y: y - 105))
        context.fill(brim, with: .color(.black))
        
        // Head
        var head = Path()
        head.addEllipse(in: CGRect(x: x - 25, y: y - 120, width: 50, height: 50))
        context.fill(head, with: .color(color))
        
        // Broom
        var broom = Path()
        broom.move(to: CGPoint(x: x - 85, y: y + 40))
        broom.addLine(to: CGPoint(x: x + 75, y: y - 30))
        context.stroke(broom, with: .color(.brown), lineWidth: 10)
    }
}

struct Bunny {
    var bnx: CGFloat = 0
    var bny: CGFloat = 0
    var bns: CGFloat = CGFloat.random(in: -5...5)
    var bnsp: CGFloat = CGFloat.random(in: -5...5)
    var s: CGFloat = 0
    
    mutating func move(size: CGSize) {
        bnx += bns
        bny += bnsp
        
        if bnx > size.width || bnx < 0 {
            bns *= -1
        }
        
        if bny > size.height || bny < 0 {
            bnsp *= -1
        }
        
        if s <= 1.7 {
            s += 0.001
        }
    }
    
    func draw(context: inout GraphicsContext) {
        // Body
        var body = Path()
        body.addEllipse(in: CGRect(x: bnx - 25, y: bny - 25, width: 50, height: 50))
        context.fill(body, with: .color(.white))
        
        // Head
        var head = Path()
        head.addEllipse(in: CGRect(x: bnx - 10, y: bny - 40, width: 20, height: 30))
        context.fill(head, with: .color(.white))
        
        // Ears
        var leftEar = Path()
        leftEar.move(to: CGPoint(x: bnx - 5, y: bny - 40))
        leftEar.addLine(to: CGPoint(x: bnx - 15, y: bny - 60))
        leftEar.addLine(to: CGPoint(x: bnx - 5, y: bny - 50))
        context.fill(leftEar, with: .color(.white))
        
        var rightEar = Path()
        rightEar.move(to: CGPoint(x: bnx + 5, y: bny - 40))
        rightEar.addLine(to: CGPoint(x: bnx + 15, y: bny - 60))
        rightEar.addLine(to: CGPoint(x: bnx + 5, y: bny - 50))
        context.fill(rightEar, with: .color(.white))
        
        // Eyes
        var leftEye = Path()
        leftEye.addEllipse(in: CGRect(x: bnx - 8, y: bny - 35, width: 5, height: 5))
        context.fill(leftEye, with: .color(.black))
        
        var rightEye = Path()
        rightEye.addEllipse(in: CGRect(x: bnx + 3, y: bny - 35, width: 5, height: 5))
        context.fill(rightEye, with: .color(.black))
    }
}

// Simplified versions of other game objects
struct SG {
    var x: CGFloat = CGFloat.random(in: 0..<400)
    var y: CGFloat = CGFloat.random(in: -800..<0)
    let size: CGFloat = CGFloat.random(in: 10...30)
    let color = Color(
        red: Double.random(in: 0...1),
        green: Double.random(in: 0...1),
        blue: Double.random(in: 0...1)
    )
    
    mutating func move() {
        y += CGFloat.random(in: 1...5)
    }
    
    func draw(context: inout GraphicsContext) {
        var path = Path()
        path.addEllipse(in: CGRect(x: x, y: y, width: size, height: size))
        context.fill(path, with: .color(color))
    }
}

struct GG {
    var x: CGFloat = CGFloat.random(in: 0..<400)
    var y: CGFloat = CGFloat.random(in: -800..<0)
    let size: CGFloat = CGFloat.random(in: 10...30)
    let color = Color(
        red: Double.random(in: 0...1),
        green: Double.random(in: 0...1),
        blue: Double.random(in: 0...1)
    )
    
    mutating func move(size: CGSize) {
        y += CGFloat.random(in: 1...5)
    }
    
    func draw(context: inout GraphicsContext) {
        var path = Path()
        path.addEllipse(in: CGRect(x: x, y: y, width: size, height: size))
        context.fill(path, with: .color(color))
    }
}

struct LG {
    var x: CGFloat = CGFloat.random(in: 0..<400)
    var y: CGFloat = CGFloat.random(in: -800..<0)
    let size: CGFloat = CGFloat.random(in: 10...30)
    let color = Color(
        red: Double.random(in: 0...1),
        green: Double.random(in: 0...1),
        blue: Double.random(in: 0...1)
    )
    
    mutating func move(size: CGSize) {
        y += CGFloat.random(in: 1...5)
    }
    
    func draw(context: inout GraphicsContext) {
        var path = Path()
        path.addEllipse(in: CGRect(x: x, y: y, width: size, height: size))
        context.fill(path, with: .color(color))
    }
}

struct CG {
    var x: CGFloat = CGFloat.random(in: 0..<400)
    var y: CGFloat = CGFloat.random(in: -800..<0)
    let size: CGFloat = CGFloat.random(in: 10...30)
    let color = Color(
        red: Double.random(in: 0...1),
        green: Double.random(in: 0...1),
        blue: Double.random(in: 0...1)
    )
    
    mutating func move(size: CGSize) {
        y += CGFloat.random(in: 1...5)
    }
    
    func draw(context: inout GraphicsContext) {
        var path = Path()
        path.addEllipse(in: CGRect(x: x, y: y, width: size, height: size))
        context.fill(path, with: .color(color))
    }
}

// MARK: - Preview
struct HalloweenGame_Previews: PreviewProvider {
    static var previews: some View {
        HalloweenGame()
            .previewInterfaceOrientation(.landscapeRight)
    }
}
