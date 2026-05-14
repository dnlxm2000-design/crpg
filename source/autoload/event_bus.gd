# event_bus.gd — Global event bus for decoupled communication.
# Attach as an Autoload singleton named "EventBus".
# Usage: EventBus.something_happened.emit(args...)
extends Node

## Real-time mode signals
signal realtime_mode_entered()
signal realtime_mode_exited()

## Turn-based mode signals
signal turn_mode_entered()
signal turn_mode_exited()

## Turn system signals
signal turn_started(unit: Node)
signal turn_ended(unit: Node)
signal round_started(round: int)
signal round_ended(round: int)
signal turn_order_changed(order: Array)

## Unit signals
signal unit_damaged(unit: Node, amount: int, source: Node)
signal unit_evaded(target: Node, source: Node)  # Attack missed (target dodged)
signal unit_destroyed(unit: Node)
signal unit_moved(unit: Node, from: Vector2, to: Vector2)
signal ap_changed(unit: Node)

## Combat signals
signal combat_started(participants: Array)
signal combat_ended()
signal combat_victory()
signal combat_defeat()

## Mode switch signal
signal game_mode_changed(mode: String)  # "realtime" | "turnbased" | "menu"

## Input signals
signal action_issued(unit: Node, action: String, target: Variant)

## Movement signals
signal unit_skipped_turn(unit: Node)
signal player_ended_turn(unit: Node)
signal path_computed(unit: Node, path: Array)

## ZOC signals
signal attack_of_opportunity(attacker: Node, target: Node, damage: int, hit: bool)

## Economy signals
signal gold_changed(unit: Node, amount: int)
