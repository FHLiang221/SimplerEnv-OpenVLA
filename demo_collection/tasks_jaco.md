# Jaco Arm Data Collection Commands

## **Picking Tasks** (70 episodes total)

```bash
# Horizontal coke can pickup (good for grasp diversity)
python rlds_jaco.py google_robot_pick_horizontal_coke_can 10

# Vertical coke can pickup (different orientation)
python rlds_jaco.py google_robot_pick_vertical_coke_can 10

# Standing coke can pickup (upright grasp)
python rlds_jaco.py google_robot_pick_standing_coke_can 10

# General coke can pickup (randomized orientation)
python rlds_jaco.py google_robot_pick_coke_can 10

# Generic object pickup (diverse objects)
python rlds_jaco.py google_robot_pick_object 20

# Pick apple (specific object)
python rlds_jaco.py google_robot_pick_apple 10

# Pick sponge (specific object)
python rlds_jaco.py google_robot_pick_sponge 10
```

## **Drawer Tasks**

### Opening drawers (different levels) - 60 episodes
```bash
# Top drawer opening (highest reach)
python rlds_jaco.py google_robot_open_top_drawer 20

# Middle drawer opening (mid-level reach)
python rlds_jaco.py google_robot_open_middle_drawer 20

# Bottom drawer opening (low reach, challenging)
python rlds_jaco.py google_robot_open_bottom_drawer 20
```

### Closing drawers (different levels) - 60 episodes
```bash
# Top drawer closing
python rlds_jaco.py google_robot_close_top_drawer 20

# Middle drawer closing
python rlds_jaco.py google_robot_close_middle_drawer 20

# Bottom drawer closing
python rlds_jaco.py google_robot_close_bottom_drawer 20
```

## **Placement Tasks** - 40 episodes

```bash
# Place apple in closed top drawer (pick + place + open sequence)
python rlds_jaco.py google_robot_place_apple_in_closed_top_drawer 20

# General placement in closed drawer
python rlds_jaco.py google_robot_place_in_closed_drawer 20
```

## **Moving Tasks** - 20 episodes

```bash
# Move objects near target locations
python rlds_jaco.py google_robot_move_near 20
```

---

**Push Task**
python EE.py google_robot_push_coke_can 100