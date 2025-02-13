import Foundation
import XCTest

@testable import XMTPiOS

@available(iOS 15, *)
class ReactionTests: XCTestCase {

	func testCanDecodeLegacyForm() async throws {
		let codec = ReactionCodec()

		// This is how clients send reactions now.
		let canonicalEncoded = EncodedContent.with {
			$0.type = ContentTypeReaction
			$0.content = Data(
				"""
				{
				  "action": "added",
				  "content": "smile",
				  "reference": "abc123",
				  "schema": "shortcode"
				}
				""".utf8)
		}

		// Previously, some clients sent reactions like this.
		// So we test here to make sure we can still decode them.
		let legacyEncoded = EncodedContent.with {
			$0.type = ContentTypeReaction
			$0.parameters = [
				"action": "added",
				"reference": "abc123",
				"schema": "shortcode",
			]
			$0.content = Data("smile".utf8)
		}

		let fixtures = try await fixtures()
		let canonical = try codec.decode(
			content: canonicalEncoded, client: fixtures.alixClient)
		let legacy = try codec.decode(
			content: legacyEncoded, client: fixtures.alixClient)

		XCTAssertEqual(ReactionAction.added, canonical.action)
		XCTAssertEqual(ReactionAction.added, legacy.action)
		XCTAssertEqual("smile", canonical.content)
		XCTAssertEqual("smile", legacy.content)
		XCTAssertEqual("abc123", canonical.reference)
		XCTAssertEqual("abc123", legacy.reference)
		XCTAssertEqual(ReactionSchema.shortcode, canonical.schema)
		XCTAssertEqual(ReactionSchema.shortcode, legacy.schema)
	}

	func testCanUseReactionCodec() async throws {
		let fixtures = try await fixtures()
		let conversation = try await fixtures.alixClient.conversations
			.newConversation(with: fixtures.boClient.address)

		fixtures.alixClient.register(codec: ReactionCodec())

		_ = try await conversation.send(text: "hey alix 2 bo")

		let messageToReact = try await conversation.messages()[0]

		let reaction = Reaction(
			reference: messageToReact.id,
			action: .added,
			content: "U+1F603",
			schema: .unicode
		)

		try await conversation.send(
			content: reaction,
			options: .init(contentType: ContentTypeReaction)
		)

		_ = try await conversation.messages()

		let message = try await conversation.messages()[0]
		let content: Reaction = try message.content()
		XCTAssertEqual("U+1F603", content.content)
		XCTAssertEqual(messageToReact.id, content.reference)
		XCTAssertEqual(ReactionAction.added, content.action)
		XCTAssertEqual(ReactionSchema.unicode, content.schema)
	}

	func testCanDecodeEmptyForm() async throws {
		let codec = ReactionCodec()

		// This is how clients send reactions now.
		let canonicalEncoded = EncodedContent.with {
			$0.type = ContentTypeReaction
			$0.content = Data(
				"""
				{
				  "action": "",
				  "content": "smile",
				  "reference": "",
				  "schema": ""
				}
				""".utf8)
		}

		// Previously, some clients sent reactions like this.
		// So we test here to make sure we can still decode them.
		let legacyEncoded = EncodedContent.with {
			$0.type = ContentTypeReaction
			$0.parameters = [
				"action": "",
				"reference": "",
				"schema": "",
			]
			$0.content = Data("smile".utf8)
		}

		let fixtures = try await fixtures()

		let canonical = try codec.decode(
			content: canonicalEncoded, client: fixtures.alixClient)
		let legacy = try codec.decode(
			content: legacyEncoded, client: fixtures.alixClient)

		XCTAssertEqual(ReactionAction.unknown, canonical.action)
		XCTAssertEqual(ReactionAction.unknown, legacy.action)
		XCTAssertEqual("smile", canonical.content)
		XCTAssertEqual("smile", legacy.content)
		XCTAssertEqual("", canonical.reference)
		XCTAssertEqual("", legacy.reference)
		XCTAssertEqual(ReactionSchema.unknown, canonical.schema)
		XCTAssertEqual(ReactionSchema.unknown, legacy.schema)
	}
}
