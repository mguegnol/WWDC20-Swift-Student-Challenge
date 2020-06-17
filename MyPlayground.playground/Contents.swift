//: A SpriteKit based Playground

// Made by Maxence GUEGNOLLE--SANTI
// On 05/2020

import PlaygroundSupport
import SpriteKit
import SwiftUI

struct ContentView : View {
	
	@State var maskState: Bool = false
	@State var confinementState: Bool = false
	
	@State var scene: GameScene = GameScene(fileNamed: "GameScene")!
	
    var body: some View {
		VStack(spacing: 0) {
			SKViewContainer(scene: $scene)
			VStack {
				HStack(spacing:20) {
					HStack(spacing:10) {
						Text("Sane")
						ZStack {
							Circle().fill(Color.green)
							Circle().stroke(Color.black, lineWidth: 1.2)
						}.frame(width: 15, height: 15)
					}
					HStack(spacing:10) {
						Text("Incubation")
						ZStack {
							Circle().fill(Color.orange)
							Circle().stroke(Color.black, lineWidth: 1.2)
						}.frame(width: 15, height: 15)
					}
					HStack(spacing:10) {
						Text("Sick")
						ZStack {
							Circle().fill(Color.red)
							Circle().stroke(Color.black, lineWidth: 1.2)
						}.frame(width: 15, height: 15)
					}
					HStack(spacing:10) {
						Text("Immune")
						ZStack {
							Circle().fill(Color.blue)
							Circle().stroke(Color.black, lineWidth: 1.2)
						}.frame(width: 15, height: 15)
					}
					HStack(spacing:10) {
						Text("Wearing Mask")
						ZStack {
							Circle().fill(Color.white)
							Circle().stroke(Color.black, lineWidth: 1.2)
							Circle().fill(Color.black)
								.frame(width: 5, height: 5)
						}.frame(width: 15, height: 15)
					}
				}.padding([.top, .bottom], 10)
					.frame(width: 640)
					.background(Color.gray.opacity(0.5))
				Spacer()
				HStack(spacing: 20) {
					HStack(spacing: 10) {
						Text("Add Sane")
						ZStack {
							Circle().fill(Color.green)
							Circle().stroke(Color.black, lineWidth: 1.2)
							Image(systemName: "plus")
						}.frame(width: 30, height: 30)
							.onTapGesture {
								let person  = self.scene.createAndAddPerson()
								self.scene.personArray.append(person)
							}
					}
					HStack(spacing: 10) {
						Text("Add Sick")
						ZStack {
							Circle().fill(Color.red)
							Circle().stroke(Color.black, lineWidth: 1.2)
							Image(systemName: "plus")
						}.frame(width: 30, height: 30)
							.onTapGesture {
								let person  = self.scene.createAndAddPerson()
								self.scene.runInfectSequence(person)
								self.scene.personArray.append(person)
							}
					}
					Toggle("Masks", isOn: $maskState)
						.frame(width: 110)
						.onTapGesture {
							if !self.maskState {
								for person in self.scene.personArray {
									person.addMask()
								}
							} else {
								for person in self.scene.personArray {
									person.removeMask()
								}
							}
						}
					Toggle("Lockdown", isOn: $confinementState)
						.frame(width: 140)
						.onTapGesture {
							if !self.confinementState {
								self.scene.startConfinement()
							} else {
								self.scene.endConfinement()
							}
					}
					Button(action: {
						for p in self.scene.personArray {
							p.removeFromParent()
						}
						for c in self.scene.confCircleArray {
							c.removeFromParent()
						}
						self.scene.personArray = []
						self.scene.confCircleArray = []
						self.maskState = false
						self.confinementState = false
						
						for _ in 0..<3 {
							self.scene.personArray.append(self.scene.createAndAddPerson())
						}
					}) {
						Text("Reset").foregroundColor(.red)
					}
				}
				Spacer()
			}.frame(height: 120)
			.background(Color.white)
		}
		
	}
}

struct SKViewContainer: UIViewRepresentable {
	
	@Binding var scene: GameScene

    func makeUIView(context: Context) -> SKView {

		// Load the SKScene from 'GameScene.sks'
		let sceneView = SKView(frame: CGRect(x:0 , y:0, width: 640, height: 480))
		scene.scaleMode = .aspectFit
		sceneView.presentScene(scene)
        return sceneView
    }

    func updateUIView(_ uiView: SKView, context: Context) {}

}

class PersonSN: SKShapeNode {
	var isImmune: Bool = false
	var isContaminated: Bool = false
	var isWearingMask: Bool = false
	
	func addMask() {
		
//		self.strokeColor = SKColor.white
//		self.glowWidth = 2.0
		let mask = SKShapeNode(circleOfRadius: 5)
		mask.name = "mask"
		mask.fillColor = SKColor.black
		mask.strokeColor = SKColor.black
		//mask.glowWidth = 0
		isWearingMask = true
		self.addChild(mask)
	}
	
	func removeMask() {
		if let mask = self.childNode(withName: "mask") as? SKShapeNode {
			mask.removeFromParent()
			isWearingMask = false
		}
	}
}

class GameScene: SKScene, SKPhysicsContactDelegate {
	
	var personArray: [PersonSN] = []
	var confCircleArray: [SKShapeNode] = []
	
	var timer = Timer()
	
    override func didMove(to view: SKView) {
		self.physicsWorld.contactDelegate = self
		self.physicsWorld.gravity = CGVector(dx: 0.0, dy: 0.0)
		for _ in 0..<3 {
			personArray.append(createAndAddPerson())
		}
		wall()
		scheduledTimerWithTimeInterval()
    }
    
    @objc static override var supportsSecureCoding: Bool {
        // SKNode conforms to NSSecureCoding, so any subclass going
        // through the decoding process must support secure coding
        get {
            return true
        }
    }
	
	func wall() {
		let wall = SKShapeNode(rect: CGRect(x: 0, y: 0, width: 640, height: 480))
		wall.strokeColor = SKColor.clear
//		wall.lineWidth = 2
		wall.position = CGPoint(x: size.width/2-wall.frame.width/2, y: size.height/2-wall.frame.height/2)
		self.addChild(wall)
		
		wall.physicsBody = SKPhysicsBody(edgeLoopFrom: wall.path!)
		wall.physicsBody?.restitution = 1.0
		wall.physicsBody?.friction = 0.0
		wall.physicsBody?.linearDamping = 0.0
		wall.physicsBody?.angularDamping = 0.0

		wall.physicsBody?.categoryBitMask = 4
	}

	func createAndAddPerson() -> PersonSN {
		let circle = PersonSN(circleOfRadius: 10) // Create circle
		circle.position = randomPosition()
		circle.strokeColor = SKColor.black
		circle.glowWidth = 1.0
		circle.fillColor = SKColor.green
		
		self.addChild(circle)
		
		//startMoveActionForever(circle)
		
		circle.physicsBody = SKPhysicsBody(circleOfRadius: circle.frame.size.height/2)
		circle.physicsBody?.categoryBitMask = 8
		circle.physicsBody?.contactTestBitMask = 8 //8 here
		circle.physicsBody?.collisionBitMask = 3 | 4
		
		circle.physicsBody?.restitution = 1.0
		circle.physicsBody?.friction = 0.0
		circle.physicsBody?.linearDamping = 0.0
		circle.physicsBody?.angularDamping = 0.0
		
		circle.physicsBody?.applyForce(CGVector(dx: 200, dy: 200))
		
		return circle
		
	}
	
	func startMoveActionForever(_ circle: PersonSN) {
		let randomPos = randomPosition()
		let duration = distance(randomPos, circle.position)
		circle.run(SKAction.move(to: randomPos, duration: TimeInterval(duration/150)), completion: {
			[weak self] in self?.startMoveActionForever(circle)
		})
	}
	
	func distance(_ a: CGPoint, _ b: CGPoint) -> CGFloat {
		let xDist = a.x - b.x
		let yDist = a.y - b.y
		return CGFloat(sqrt(xDist * xDist + yDist * yDist))
	}
	
	func randomPosition() -> CGPoint {
		let height = Int(self.view?.frame.height ?? 0)
		let width = Int(self.view?.frame.width ?? 0)

		let randomPosition = CGPoint(x: Int.random(in: 0..<width), y: Int.random(in: 0..<height))
		
		return randomPosition
    }
	
	func randomPositionForSizedItem(width: CGFloat, height: CGFloat) -> CGPoint {
		let centerWidth = Int(width/2) + 20
		let centerHeight = Int(height/2) + 20
		
		let height = Int(self.view?.frame.height ?? 0) - centerWidth
		let width = Int(self.view?.frame.width ?? 0) - centerHeight

		let randomPosition = CGPoint(x: Int.random(in: 0+centerWidth..<width), y: Int.random(in: 0+centerHeight..<height))
		
		return randomPosition
	}
	
	func getProtectionLevel(_ mask1: Bool, _ mask2: Bool) -> Int {
		if mask1 && mask2 {
			return 9
		} else if mask1 || mask2 {
			return 7
		} else {
			return 0
		}
	}
	
	func didBegin(_ contact: SKPhysicsContact) {
//		print("Collision")
		guard let bodyA = contact.bodyA.node as? PersonSN else {return}
		guard let bodyB = contact.bodyB.node as? PersonSN else {return}
		
		if bodyA.isContaminated && !bodyB.isImmune {
//			A is infected but not B. Infect B
//			print("Infect B")
			if Int.random(in: 1...10) > getProtectionLevel(bodyA.isWearingMask, bodyB.isWearingMask) {
				runInfectSequence(bodyB)
			}
		} else if bodyB.isContaminated && !bodyA.isImmune {
//			B is infected but not A. Infect A
//			print("Infect A")
			if Int.random(in: 1...10) > getProtectionLevel(bodyA.isWearingMask, bodyB.isWearingMask) {
				runInfectSequence(bodyA)
			}
		}
	}
	
	func runInfectSequence(_ circle: PersonSN) {
		let state = SKAction.run({circle.isImmune = true; circle.isContaminated = true})
		let orange = SKAction.run({circle.fillColor = SKColor.orange})
		let wait3sec = SKAction.wait(forDuration: 3)
		let red = SKAction.run({circle.fillColor = SKColor.red})
		let wait7sec = SKAction.wait(forDuration: 7)
		let blue = SKAction.run({circle.fillColor = SKColor.blue})
		let deContaminate = SKAction.run({circle.isContaminated = false})
		
		let seq = SKAction.sequence([state, orange, wait3sec, red, wait7sec, blue, deContaminate])
		circle.run(seq)
	}
	
}

extension GameScene {

	func addConfinementCircle() {
		let path = UIBezierPath()
		path.addArc(withCenter: CGPoint.zero,
					radius: 70,
					startAngle: 3*CGFloat.pi/2,
					endAngle: CGFloat.pi * 2 * 0.934 - CGFloat.pi/2,
					clockwise: true)
		
		let section = SKShapeNode(path: path.cgPath)
		section.strokeColor = SKColor.gray
		section.lineWidth = 5
		section.position = randomPositionForSizedItem(width: section.frame.size.width, height: section.frame.size.height)
		
		var angle = Double.random(in: 0..<Double.pi)
		let posNeg = Int.random(in: 0..<2)
		if posNeg%2 == 1 {
			angle = angle * -1
		}
		section.zRotation = CGFloat(angle)
		
		self.addChild(section)
		
		var intersect = true
		while (intersect) {
			intersect = false
			for confCircle in confCircleArray {
				if (section.intersects(confCircle)) {
					intersect = true
					section.position = randomPositionForSizedItem(width: section.frame.size.width, height: section.frame.size.height)
					break
				}
			}
		}
		
		//self.addChild(section)
		confCircleArray.append(section)
		
		section.physicsBody = SKPhysicsBody(edgeChainFrom: path.cgPath)
		section.physicsBody?.categoryBitMask = 3
		section.physicsBody?.contactTestBitMask = 0
		section.physicsBody?.collisionBitMask = 0
		
		section.physicsBody?.restitution = 1.0
		section.physicsBody?.friction = 0.0
		section.physicsBody?.linearDamping = 0.0
		section.physicsBody?.angularDamping = 0.0
	}
	
	func startConfinement() {
		if personArray.count == 0 {
			return
		}
		for _ in 0..<3 {
			addConfinementCircle()
		}
		
		let repartition = personArray.count / 3
	
		var t = 0 //Keep trace of positioned person
		var rest = 0 //Adding rest of division
		for confCircle in confCircleArray {
			if confCircleArray.last == confCircle && personArray.count > 3 {
				rest += personArray.count % 3
			}
			for i in t..<repartition+t+rest {
				personArray[i].position = confCircle.position
				t+=1
			}
		}
	}
	
	func endConfinement() {
		for confCircle in confCircleArray {
			confCircle.removeFromParent()
		}
		confCircleArray = []
	}
	
}

extension GameScene {
	func scheduledTimerWithTimeInterval(){
		// Scheduling timer to Call the function "updateCounting" with the interval of 1 seconds
		timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.newForce), userInfo: nil, repeats: true)
	}

	@objc func newForce() {
		for person in personArray {
//			print(person.physicsBody!.velocity)
			let dxVel = person.physicsBody!.velocity.dx
			var dxSign = copysign(1.0, dxVel)
			let dyVel = person.physicsBody!.velocity.dy
			var dySign = copysign(1.0, dyVel)
			
			if abs(dxVel) == 0 {
				let posNeg = Int.random(in: 0..<2)
				if posNeg%2 == 1 {
					dxSign = dxSign * -1
				}
			}
			if abs(dyVel) == 0 {
				let posNeg = Int.random(in: 0..<2)
				if posNeg%2 == 1 {
					dySign = dySign * -1
				}
			}
			person.physicsBody?.applyForce(CGVector(dx: dxSign*(200 - abs(dxVel)), dy: dySign*(200 - abs(dyVel))))
		}
	}
}



let view = UIHostingController(rootView: ContentView())
view.preferredContentSize = CGSize(width: 640, height: 600)
PlaygroundPage.current.liveView = view
