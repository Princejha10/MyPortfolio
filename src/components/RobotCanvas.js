"use client";
import { useEffect, useRef } from "react";
import * as THREE from "three";

export default function RobotCanvas({ isScrolled, chatOpen, clickTrigger, onInteractionComplete }) {
  const containerRef = useRef(null);
  
  // Track all props inside refs to read dynamically in the anim loop without scene restarts
  const onCompleteRef = useRef(onInteractionComplete);
  const clickRef = useRef(clickTrigger);
  const isScrolledRef = useRef(isScrolled);
  const chatOpenRef = useRef(chatOpen);

  useEffect(() => {
    onCompleteRef.current = onInteractionComplete;
    clickRef.current = clickTrigger;
    isScrolledRef.current = isScrolled;
    chatOpenRef.current = chatOpen;
  }, [onInteractionComplete, clickTrigger, isScrolled, chatOpen]);

  useEffect(() => {
    const container = containerRef.current;
    if (!container) return;

    // 1. Scene Setup
    const scene = new THREE.Scene();
    const camera = new THREE.PerspectiveCamera(42, 1, 0.1, 100);
    camera.position.set(0, 0.1, 6.2);

    const renderer = new THREE.WebGLRenderer({ antialias: true, alpha: true });
    renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
    renderer.setSize(320, 320);
    renderer.shadowMap.enabled = true;
    container.appendChild(renderer.domElement);

    // 2. Lights
    const ambientLight = new THREE.AmbientLight(0xffffff, 1.8);
    scene.add(ambientLight);

    const dirLight = new THREE.DirectionalLight(0xffffff, 2.5);
    dirLight.position.set(4, 8, 4);
    scene.add(dirLight);

    const pointLight = new THREE.PointLight(0x00f0ff, 1.8, 8);
    pointLight.position.set(0, -1, 1.5);
    scene.add(pointLight);

    // 3. Materials
    const bodyMat = new THREE.MeshStandardMaterial({
      color: 0xfcfcfc,
      roughness: 0.12,
      metalness: 0.06,
    });

    const visorMat = new THREE.MeshStandardMaterial({
      color: 0x050505,
      roughness: 0.05,
      metalness: 0.8,
    });

    const glowMat = new THREE.MeshBasicMaterial({
      color: 0x00f0ff,
    });

    const jointMat = new THREE.MeshStandardMaterial({
      color: 0x222222,
      roughness: 0.35,
      metalness: 0.4,
    });

    // 4. Mesh Structures
    const robot = new THREE.Group();
    scene.add(robot);

    // Head
    const headGroup = new THREE.Group();
    headGroup.position.set(0, 0.6, 0);
    robot.add(headGroup);

    const headGeo = new THREE.SphereGeometry(0.82, 32, 32);
    const head = new THREE.Mesh(headGeo, bodyMat);
    head.scale.set(1, 0.9, 1);
    headGroup.add(head);

    // Visor
    const visorGeo = new THREE.SphereGeometry(0.70, 32, 16);
    const visor = new THREE.Mesh(visorGeo, visorMat);
    visor.scale.set(1.02, 0.65, 0.45);
    visor.position.set(0, 0.04, 0.54);
    headGroup.add(visor);

    // Eyes
    const eyeGeo = new THREE.SphereGeometry(0.08, 16, 16);
    const leftEye = new THREE.Mesh(eyeGeo, glowMat);
    leftEye.position.set(-0.25, 0.05, 0.86);
    leftEye.scale.set(1, 0.6, 1);
    headGroup.add(leftEye);

    const rightEye = new THREE.Mesh(eyeGeo, glowMat);
    rightEye.position.set(0.25, 0.05, 0.86);
    rightEye.scale.set(1, 0.6, 1);
    headGroup.add(rightEye);

    // Ears
    const earGeo = new THREE.CylinderGeometry(0.16, 0.16, 0.1, 32);
    const leftEar = new THREE.Mesh(earGeo, jointMat);
    leftEar.position.set(-0.82, 0, 0);
    leftEar.rotation.z = Math.PI / 2;
    headGroup.add(leftEar);

    const rightEar = new THREE.Mesh(earGeo, jointMat);
    rightEar.position.set(0.82, 0, 0);
    rightEar.rotation.z = Math.PI / 2;
    headGroup.add(rightEar);

    // Antenna
    const antStemGeo = new THREE.CylinderGeometry(0.02, 0.02, 0.25, 8);
    const antStem = new THREE.Mesh(antStemGeo, jointMat);
    antStem.position.set(0, 0.9, 0);
    headGroup.add(antStem);

    const antNode = new THREE.Mesh(new THREE.SphereGeometry(0.05, 12, 12), glowMat);
    antNode.position.set(0, 1.05, 0);
    headGroup.add(antNode);

    // Body
    const bodyGroup = new THREE.Group();
    robot.add(bodyGroup);

    const bodyGeo = new THREE.SphereGeometry(0.85, 32, 32);
    const body = new THREE.Mesh(bodyGeo, bodyMat);
    body.scale.set(1, 1.05, 0.9);
    body.position.set(0, -0.4, 0);
    bodyGroup.add(body);

    // Chest Panel
    const badgeGeo = new THREE.BoxGeometry(0.38, 0.14, 0.1);
    const badge = new THREE.Mesh(badgeGeo, jointMat);
    badge.position.set(0, -0.2, 0.8);
    badge.rotation.x = 0.25;
    bodyGroup.add(badge);

    const badgeGlow = new THREE.Mesh(new THREE.BoxGeometry(0.28, 0.04, 0.11), glowMat);
    badgeGlow.position.set(0, -0.2, 0.82);
    badgeGlow.rotation.x = 0.25;
    bodyGroup.add(badgeGlow);

    // Thrusters
    const baseGeo = new THREE.TorusGeometry(0.36, 0.07, 16, 32);
    const baseRing = new THREE.Mesh(baseGeo, jointMat);
    baseRing.position.set(0, -1.15, 0);
    baseRing.rotation.x = Math.PI / 2;
    bodyGroup.add(baseRing);

    const coneGeo = new THREE.ConeGeometry(0.34, 0.45, 32, 1, true);
    const thrusterCone = new THREE.Mesh(coneGeo, glowMat);
    thrusterCone.position.set(0, -1.38, 0);
    thrusterCone.scale.set(1, -1, 1);
    bodyGroup.add(thrusterCone);

    // Arms
    const leftArmGroup = new THREE.Group();
    leftArmGroup.position.set(-1.0, -0.15, 0);
    bodyGroup.add(leftArmGroup);

    const armJointGeo = new THREE.SphereGeometry(0.12, 16, 16);
    const leftJoint = new THREE.Mesh(armJointGeo, jointMat);
    leftArmGroup.add(leftJoint);

    const armSegmentGeo = new THREE.CylinderGeometry(0.09, 0.09, 0.65, 16);
    const leftArmSeg = new THREE.Mesh(armSegmentGeo, bodyMat);
    leftArmSeg.position.set(-0.08, -0.3, 0);
    leftArmSeg.rotation.z = 0.15;
    leftArmGroup.add(leftArmSeg);

    const handGeo = new THREE.SphereGeometry(0.1, 12, 12);
    const leftHand = new THREE.Mesh(handGeo, jointMat);
    leftHand.position.set(-0.12, -0.62, 0);
    leftArmGroup.add(leftHand);

    const rightArmGroup = new THREE.Group();
    rightArmGroup.position.set(1.0, -0.15, 0);
    bodyGroup.add(rightArmGroup);

    const rightJoint = new THREE.Mesh(armJointGeo, jointMat);
    rightArmGroup.add(rightJoint);

    const rightArmSeg = new THREE.Mesh(armSegmentGeo, bodyMat);
    rightArmSeg.position.set(0.1, -0.3, 0);
    rightArmSeg.rotation.z = -0.15;
    rightArmGroup.add(rightArmSeg);

    const rightHand = new THREE.Mesh(handGeo, jointMat);
    rightHand.position.set(0.15, -0.62, 0);
    rightArmGroup.add(rightHand);

    // 5. Anim references
    let mouse = { x: 0, y: 0 };
    let targetRotationX = 0;
    let targetRotationY = 0;
    let time = 0;

    // Click sequence variables
    let lastFiredClickCount = clickRef.current;
    let isTriggeringChat = false;
    let chatStartTime = 0;
    let hasCallbackFired = false;

    // Emotion triggers
    let activeEmotion = "none";
    let emotionStartTime = 0;
    let nextEmotionTime = Date.now() + Math.random() * 5000 + 4000;

    const handleMouseMove = (e) => {
      mouse.x = (e.clientX / window.innerWidth) * 2 - 1;
      mouse.y = -(e.clientY / window.innerHeight) * 2 + 1;
      targetRotationY = mouse.x * 0.45;
      targetRotationX = -mouse.y * 0.35;
    };

    const handleMouseLeave = () => {
      targetRotationX = 0;
      targetRotationY = 0;
    };

    window.addEventListener("mousemove", handleMouseMove);
    document.addEventListener("mouseleave", handleMouseLeave);

    // 6. Core loop
    const animate = () => {
      time += 0.03;

      if (!containerRef.current) return;

      const now = Date.now();

      // Check if clickCount has updated (react to click triggers)
      if (clickRef.current > lastFiredClickCount) {
        lastFiredClickCount = clickRef.current;
        isTriggeringChat = true;
        chatStartTime = now;
        hasCallbackFired = false;
      }

      // Check click sequence animation state
      if (isTriggeringChat) {
        const chatElapsed = now - chatStartTime;

        if (chatElapsed < 1800) {
          // Smile eyes
          leftEye.scale.set(1.4, 0.15, 1);
          leftEye.rotation.z = -0.22;
          rightEye.scale.set(1.4, 0.15, 1);
          rightEye.rotation.z = 0.22;

          // Wave arm
          rightArmGroup.rotation.z = Math.sin(time * 14) * 0.7 - 1.3;
          rightArmGroup.rotation.x = Math.cos(time * 5) * 0.2;

          // Head nod + bounce
          headGroup.rotation.z = 0.15;
          headGroup.rotation.y = 0.1;
          headGroup.rotation.x = -0.05 + Math.sin(time * 8) * 0.06;
          robot.position.y = Math.sin(time * 8) * 0.25;
        } else {
          isTriggeringChat = false;
          if (!hasCallbackFired && onCompleteRef.current) {
            onCompleteRef.current();
            hasCallbackFired = true;
          }
          // Restore joints
          rightArmGroup.rotation.z = 0;
          rightArmGroup.rotation.x = 0;
          headGroup.rotation.z = 0;
        }
      } else {
        // (A) Check random emotions triggers
        if (now > nextEmotionTime && activeEmotion === "none") {
          const emotions = ["smile", "wave", "look-left", "look-right", "head-tilt", "bounce"];
          activeEmotion = emotions[Math.floor(Math.random() * emotions.length)];
          emotionStartTime = now;
        }

        // Apply active random emotions
        if (activeEmotion !== "none") {
          const elapsed = now - emotionStartTime;
          const emotionDuration = activeEmotion === "wave" ? 2200 : 1500;

          if (elapsed < emotionDuration) {
            if (activeEmotion === "smile") {
              leftEye.scale.set(1.4, 0.15, 1);
              leftEye.rotation.z = -0.22;
              rightEye.scale.set(1.4, 0.15, 1);
              rightEye.rotation.z = 0.22;
            } else if (activeEmotion === "wave") {
              rightArmGroup.rotation.z = Math.sin(time * 10) * 0.5 - 1.3;
            } else if (activeEmotion === "look-left") {
              headGroup.rotation.y += (-0.35 - headGroup.rotation.y) * 0.08;
            } else if (activeEmotion === "look-right") {
              headGroup.rotation.y += (0.35 - headGroup.rotation.y) * 0.08;
            } else if (activeEmotion === "head-tilt") {
              headGroup.rotation.z += (0.18 - headGroup.rotation.z) * 0.08;
            } else if (activeEmotion === "bounce") {
              robot.position.y += Math.sin(time * 7) * 0.2;
            }
          } else {
            activeEmotion = "none";
            nextEmotionTime = now + Math.random() * 7000 + 5000; // 5-12s delay
          }
        }

        // (B) Default tracking & floating behaviors if no active override
        if (activeEmotion === "none" || activeEmotion === "bounce") {
          const floatOffsetY = Math.sin(time * 1.5) * 0.12;
          robot.position.y = floatOffsetY;

          rightArmGroup.rotation.z = Math.sin(time * 2) * 0.05;
          leftArmGroup.rotation.z = -Math.sin(time * 2) * 0.05;
          rightArmGroup.rotation.x = 0;
          leftArmGroup.rotation.x = 0;

          // Head follow cursor (always active, including during scrolled/chat states!)
          headGroup.rotation.y += (targetRotationY - headGroup.rotation.y) * 0.07;
          headGroup.rotation.x += (targetRotationX - headGroup.rotation.x) * 0.07;
          headGroup.rotation.z += (0 - headGroup.rotation.z) * 0.07;
        }

        // (C) Blinking
        if (activeEmotion !== "smile") {
          const blinkCycle = Math.floor(time) % 5;
          if (blinkCycle === 0 && Math.sin(time * 10) > 0.8) {
            leftEye.scale.set(1, 0.05, 1);
            rightEye.scale.set(1, 0.05, 1);
            leftEye.rotation.z = 0;
            rightEye.rotation.z = 0;
          } else {
            leftEye.scale.set(1, 0.6, 1);
            rightEye.scale.set(1, 0.6, 1);
            leftEye.rotation.z = 0;
            rightEye.rotation.z = 0;
          }
        }
      }

      // (D) Default breathing body scale
      const breathScale = 1.0 + Math.sin(time * 1.2) * 0.015;
      body.scale.set(breathScale, 1.05 + Math.cos(time * 1.2) * 0.005, 0.9);

      // (E) Thruster scaling
      const thrusterScale = 1.0 + Math.sin(time * 15) * 0.1;
      thrusterCone.scale.set(thrusterScale, -1.0 - Math.sin(time * 15) * 0.1, thrusterScale);

      renderer.render(scene, camera);
      requestAnimationFrame(animate);
    };

    animate();

    // 7. Cleanup
    return () => {
      window.removeEventListener("mousemove", handleMouseMove);
      document.removeEventListener("mouseleave", handleMouseLeave);
      if (container.contains(renderer.domElement)) {
        container.removeChild(renderer.domElement);
      }
      headGeo.dispose();
      visorGeo.dispose();
      eyeGeo.dispose();
      earGeo.dispose();
      bodyGeo.dispose();
      badgeGeo.dispose();
      baseGeo.dispose();
      coneGeo.dispose();
      armJointGeo.dispose();
      armSegmentGeo.dispose();
      handGeo.dispose();
      bodyMat.dispose();
      visorMat.dispose();
      glowMat.dispose();
      jointMat.dispose();
    };
  }, []); // Dependency array is completely empty: WebGL Canvas initializes once, never restarts!

  return (
    <div
      ref={containerRef}
      className="w-full h-full flex items-center justify-center pointer-events-none select-none"
    />
  );
}
