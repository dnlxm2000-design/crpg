# event_bus.gd — Global event bus for decoupled communication.
# Attach as an Autoload singleton named "EventBus".
# Usage: EventBus.something_happened.emit(args...)
extends Node

## Real-time mode signals
@warning_ignore("unused_signal")
signal realtime_mode_entered()
@warning_ignore("unused_signal")
signal realtime_mode_exited()

## Turn-based mode signals
@warning_ignore("unused_signal")
signal turn_mode_entered()
@warning_ignore("unused_signal")
signal turn_mode_exited()

## Turn system signals
@warning_ignore("unused_signal")
signal turn_started(unit: Node)
@warning_ignore("unused_signal")
signal turn_ended(unit: Node)
@warning_ignore("unused_signal")
signal round_started(round: int)
@warning_ignore("unused_signal")
signal round_ended(round: int)
@warning_ignore("unused_signal")
signal turn_order_changed(order: Array)

## Unit signals
@warning_ignore("unused_signal")
signal unit_damaged(unit: Node, amount: int, source: Node)
@warning_ignore("unused_signal")
signal unit_evaded(target: Node, source: Node)
@warning_ignore("unused_signal")
signal unit_destroyed(unit: Node)
@warning_ignore("unused_signal")
signal unit_moved(unit: Node, from: Vector3, to: Vector3)
@warning_ignore("unused_signal")
signal ap_changed(unit: Node)

## Combat signals
@warning_ignore("unused_signal")
signal combat_started(participants: Array)
@warning_ignore("unused_signal")
signal combat_ended()
@warning_ignore("unused_signal")
signal combat_victory()
@warning_ignore("unused_signal")
signal combat_defeat()

## Mode switch signal
@warning_ignore("unused_signal")
signal game_mode_changed(mode: String)

## Movement signals
@warning_ignore("unused_signal")
signal unit_skipped_turn(unit: Node)
@warning_ignore("unused_signal")
signal player_ended_turn(unit: Node)

## ZOC signals
@warning_ignore("unused_signal")
signal attack_of_opportunity(attacker: Node, target: Node, damage: int, hit: bool)

## Economy signals
@warning_ignore("unused_signal")
signal gold_changed(unit: Node, amount: int)
