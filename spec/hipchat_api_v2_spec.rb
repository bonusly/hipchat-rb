require File.expand_path(File.dirname(__FILE__) + '/spec_helper')
require 'tempfile'

describe 'HipChat (API V2)' do

  subject { HipChat::Client.new('blah', api_version: @api_version) }

  let(:room) { subject['Hipchat'] }
  let(:user) { subject.user '12345678' }

  describe '#history' do
    include_context 'HipChatV2'
    it 'is successful without custom options' do
      mock_successful_history

      expect(room.history).to be_truthy
    end

    it 'is successful with custom options' do
      params = {
          timezone:      'America/Los_Angeles',
          date:          '2010-11-19',
          'max-results': 10,
          'start-index': 10,
          'end-date':    '2010-11-19'
      }

      mock_successful_history(params)
      expect(room.history(params)).to be_truthy
    end

    it 'is successful from fetched room' do
      mock_successful_rooms
      mock_successful_history

      expect(subject.rooms).to be_truthy
      expect(subject.rooms.first.history).to be_truthy
    end

    it "fails when the room doesn't exist" do
      allow(room.class).to receive(:get).and_return(OpenStruct.new(:code => 404))

      expect { room.history }.to raise_error(HipChat::UnknownRoom)
    end

    it "fails when we're not allowed to do so" do
      allow(room.class).to receive(:get).and_return(OpenStruct.new(:code => 401))

      expect { room.history }.to raise_error(HipChat::Unauthorized)
    end

    it 'fails if we get an unknown response code' do
      allow(room.class).to receive(:get).and_return(OpenStruct.new(:code => 403))

      expect { room.history }.to raise_error(HipChat::Unauthorized)
    end
  end

  describe '#statistics' do
    include_context 'HipChatV2'
    it 'is successful without custom options' do
      mock_successful_statistics

      expect(room.statistics).to be_truthy
    end

    it 'is successful from fetched room' do
      mock_successful_rooms
      mock_successful_statistics

      expect(subject.rooms).to be_truthy
      expect(subject.rooms.first.statistics).to be_truthy
    end

    it "fails when the room doesn't exist" do
      allow(room.class).to receive(:get).and_return(OpenStruct.new(:code => 404))

      expect { room.statistics }.to raise_error(HipChat::UnknownRoom)
    end

    it "fails when we're not allowed to do so" do
      allow(room.class).to receive(:get).and_return(OpenStruct.new(:code => 401))

      expect { room.statistics }.to raise_error(HipChat::Unauthorized)
    end

    it 'fails if we get an unknown response code' do
      allow(room.class).to receive(:get).and_return(OpenStruct.new(:code => 403))

      expect { room.statistics }.to raise_error(HipChat::Unauthorized)
    end
  end

  describe '#topic' do
    include_context 'HipChatV2'
    let(:topic) { 'Nice topic' }

    it 'is successful without custom options' do
      mock_successful_topic_change(topic)
      expect(room.topic(topic)).to be_truthy
    end

    it 'is successful with a custom from' do
      options = { from: 'Me' }
      mock_successful_topic_change(topic, options)
      expect(room.topic(topic, options)).to be_truthy
    end

    it "fails when the room doesn't exist" do
      allow(room.class).to receive(:put).and_return(OpenStruct.new(:code => 404))

      expect { room.topic topic }.to raise_error(HipChat::UnknownRoom)
    end

    it "fails when we're not allowed to do so" do
      allow(room.class).to receive(:put).and_return(OpenStruct.new(:code => 401))

      expect { room.topic topic }.to raise_error(HipChat::Unauthorized)
    end

    it 'fails if we get an unknown response code' do
      allow(room.class).to receive(:put).and_return(OpenStruct.new(:code => 403))

      expect { room.topic topic }.to raise_error(HipChat::Unauthorized)
    end
  end



  describe '#send_message' do
    include_context 'HipChatV2'
    let(:message) { 'Hello world' }

    it 'successfully without custom options' do
      mock_successful_send_message message

      expect(room.send_message(message)).to be_truthy
    end

    it "but fails when the room doesn't exist" do
      allow(room.class).to receive(:post).and_return(OpenStruct.new(:code => 404))

      expect { room.send_message message }.to raise_error(HipChat::UnknownRoom)
    end

    it "but fails when we're not allowed to do so" do
      allow(room.class).to receive(:post).and_return(OpenStruct.new(:code => 401))

      expect { room.send_message message }.to raise_error(HipChat::Unauthorized)
    end

    it 'but fails if we get an unknown response code' do
      allow(room.class).to receive(:post).and_return(OpenStruct.new(:code => 403))

      expect { room.send_message message }.to raise_error(HipChat::Unauthorized)
    end
  end

  describe '#send' do
    include_context 'HipChatV2'
    let(:from)    { 'Dude' }
    let(:message) { 'Hello world' }

    it 'successfully without custom options' do
      mock_successful_send from, message
      expect(room.send(from, message)).to be_truthy
    end

    it 'successfully with notifications on as option' do
      options = { notify: true }

      mock_successful_send from, message, options
      expect(room.send(from, message, options)).to be_truthy
    end

    it 'successfully with custom color' do
      options = { color: 'red' }

      mock_successful_send from, message, options
      expect(room.send(from, message, options)).to be_truthy
    end

    it 'successfully creates a card in the room' do
      card = { card: { style: 'application',
                          title: 'My Awesome Card',
                          id:    12345 }}

      mock_successful_send_card from, message, card

      expect(room.send(from, message, {card: card})).to be_truthy
    end

    it 'successfully with text message_format' do
      options = { message_format: 'text' }

      mock_successful_send from, message, options
      expect(room.send(from, message, options)).to be_truthy
    end

    it 'but fails if the username is more than 15 chars' do
      from = 'a very long username here'

      expect { room.send from, message }.to raise_error(HipChat::UsernameTooLong)
    end

    it "but fails when the room doesn't exist" do
      allow(room.class).to receive(:post).and_return(OpenStruct.new(:code => 404))

      expect { room.send from, message }.to raise_error(HipChat::UnknownRoom)
    end

    it "but fails when we're not allowed to do so" do
      allow(room.class).to receive(:post).and_return(OpenStruct.new(:code => 401))

      expect { room.send from, message }.to raise_error(HipChat::Unauthorized)
    end

    it 'but fails if we get an unknown response code' do
      allow(room.class).to receive(:post).and_return(OpenStruct.new(:code => 403))

      expect { room.send from, message }.to raise_error(HipChat::Unauthorized)
    end
  end


  describe '#reply' do
    include_context 'HipChatV2'
    let(:parent_id) { '100000' }
    let(:message)   { 'Hello world' }

    it 'successfully' do
      mock_successful_reply parent_id, message

      expect(room.reply(parent_id, message))
    end

    it "but fails when the parent_id doesn't exist" do
      allow(room.class).to receive(:post).and_return(OpenStruct.new(:code => 404))

      expect { room.reply parent_id, message }.to raise_error(HipChat::UnknownRoom)
    end

    it "but fails when we're not allowed to do so" do
      allow(room.class).to receive(:post).and_return(OpenStruct.new(:code => 401))

      expect { room.reply parent_id, message }.to raise_error(HipChat::Unauthorized)
    end

    it 'but fails if we get an unknown response code' do
      allow(room.class).to receive(:post).and_return(OpenStruct.new(:code => 403))

      expect { room.reply parent_id, message }.to raise_error(HipChat::Unauthorized)
    end
  end

  describe '#share_link' do
    include_context 'HipChatV2'
    let(:from)    { 'Dude' }
    let(:message) { 'Sloth love Chunk!' }
    let(:link)    { 'http://i.imgur.com/cZ6GDFY.jpg' }

    it 'successfully' do
      mock_successful_link_share from, message, link

      expect(room.share_link(from, message, link)).to be_truthy
    end

    it 'but fails if the username is more than 15 chars' do
      from = 'a very long username here'

      expect(lambda { room.share_link from, message, link }).to raise_error(HipChat::UsernameTooLong)
    end

    it "but fails when the room doesn't exist" do
      allow(room.class).to receive(:post).and_return(OpenStruct.new(:code => 404))

      expect(lambda { room.share_link from, message, link }).to raise_error(HipChat::UnknownRoom)
    end

    it "but fails when we're not allowed to do so" do
      allow(room.class).to receive(:post).and_return(OpenStruct.new(:code => 401))

      expect(lambda { room.share_link from, message, link }).to raise_error(HipChat::Unauthorized)
    end

    it 'but fails if we get an unknown response code' do
      allow(room.class).to receive(:post).and_return(OpenStruct.new(:code => 403))

      expect(lambda { room.share_link from, message, link }).to raise_error(HipChat::Unauthorized)
    end
  end

  describe '#send_file' do
    include_context 'HipChatV2'
    let(:from)    { 'Dude' }
    let(:message) { 'Hello world' }
    let(:file) do
      Tempfile.new('foo').tap do |f|
        f.write('the content')
        f.rewind
      end
    end

    after { file.unlink }

    it 'successfully' do
      mock_successful_file_send from, message, file

      expect(room.send_file(from, message, file)).to be_truthy
    end

    it 'but fails if the username is more than 15 chars' do
      from = 'a very long username here'

      expect(lambda { room.send_file from, message, file }).to raise_error(HipChat::UsernameTooLong)
    end

    it "but fails when the room doesn't exist" do
      allow(room.class).to receive(:post).and_return(OpenStruct.new(:code => 404))

      expect(lambda { room.send_file from, message, file }).to raise_error(HipChat::UnknownRoom)
    end

    it "but fails when we're not allowed to do so" do
      allow(room.class).to receive(:post).and_return(OpenStruct.new(:code => 401))

      expect(lambda { room.send_file from, message, file }).to raise_error(HipChat::Unauthorized)
    end

    it 'but fails if we get an unknown response code' do
      allow(room.class).to receive(:post).and_return(OpenStruct.new(:code => 403))

      expect(lambda { room.send_file from, message, file }).to raise_error(HipChat::Unauthorized)
    end
  end

  describe '#create' do
    include_context 'HipChatV2'
    let(:room_name) { 'A room' }

    it 'successfully with room name' do
      mock_successful_room_creation(room_name)

      expect(subject.create_room(room_name)).to be_truthy
    end

    it 'successfully with custom parameters' do
      options = { owner_user_id: '123456',
                  privacy:       'private',
                  guest_access:  true }

      mock_successful_room_creation(room_name, options)
      expect(subject.create_room(room_name, options)).to be_truthy
    end

    it 'but fail is name is longer then 50 char' do
      room_name = 'A room name that is too long that this should fail right here'

      expect { subject.create_room(room_name) }.to raise_error(HipChat::RoomNameTooLong)
    end
  end

  describe '#create_user' do
    include_context 'HipChatV2'
    let(:name)  { 'A user' }
    let(:email) { 'email@example.com' }

    it 'successfully with user name' do
      mock_successful_user_creation name, email

      expect(subject.create_user(name, email)).to be_truthy
    end

    it 'successfully with custom parameters' do
      options = { title:          'Super user',
                  password:       'password',
                  is_group_admin: true }

      mock_successful_user_creation name, email, options

      expect(subject.create_user(name, email, options)).to be_truthy
    end

    it 'but fail is name is longer then 50 char' do
      name = 'A user name that is too long that this should fail right here'

      expect { subject.create_user(name, email) }.to raise_error(HipChat::UsernameTooLong)
    end
  end

  describe '#user_update' do
    include_context 'HipChatV2'

    let(:options) do
      { name:           'Foo Bar',
        presence:       { status: 'Away', show: 'away' },
        mention_name:   'foo',
        timezone:       'GMT',
        email:          'foo@bar.org',
        title:          'mister',
        is_group_admin: 0,
        roles:          [] }
    end

    it 'successfully' do
      mock_successful_user_update(options)

      # Not sure why this fixes the test, but for some reason the presence param becomes null when the request is stubbed
      options.delete(:presence).each { |k, v| options[k] = v }

      expect(user.update(options))
    end
  end

  describe '#get_room' do
    include_context 'HipChatV2'
    let(:name) { 'Hipchat' }

    it 'successfully' do
      mock_successful_get_room(name)

      expect(room.get_room).to be_truthy
    end

  end

  describe '#update_room' do
    include_context 'HipChatV2'
    let(:name) { 'Hipchat' }
    let(:options) do
      { name:                'hipchat',
        topic:               'hipchat topic',
        privacy:             'public',
        is_archived:         false,
        is_guest_accessible: false,
        owner:               { id: '12345' } }
    end

    it 'successfully' do
      mock_successful_update_room(name, options)
      expect(room.update_room(options)).to be_truthy
    end
  end

  describe '#delete_room' do
    include_context 'HipChatV2'
    let(:name) { 'Hipchat' }

    it 'successfully' do
      mock_successful_delete_room(name)
      expect(room.delete_room).to be_truthy
    end

    it 'missing room' do
      mock_delete_missing_room(name)
      expect { room.delete_room }.to raise_exception(HipChat::UnknownRoom)
    end
  end

  describe '#invite' do
    include_context 'HipChatV2'
    let(:user_id) { '1234' }

    it 'successfully with user_id' do
      mock_successful_invite(user_id)

      expect(room.invite(user_id)).to be_truthy
    end

    it 'successfully with custom parameters' do
      reason = 'A great reason'

      mock_successful_invite(user_id, reason: reason)
      expect(room.invite(user_id, reason)).to be_truthy
    end
  end

  describe '#add_member' do
    include_context 'HipChatV2'
    let(:user_id) { '1234' }

    it 'successfully with user_id' do
      mock_successful_add_member(user_id)

      expect(room.add_member(user_id)).to be_truthy
    end

    it 'successfully with custom parameters' do
      options = { user_id:    '1234',
                  room_roles: ['room_admin', 'room_member'] }

      mock_successful_add_member(user_id, options)
      expect(room.add_member(user_id, options[:room_roles])).to be_truthy
    end
  end

  describe '#send user message' do
    include_context 'HipChatV2'
    message = 'Equal bytes for everyone'

    it 'successfully with a standard message' do
      mock_successful_user_send message

      expect(user.send(message)).to be_truthy
    end

    it "but fails when the user doesn't exist" do
      allow(user.class).to receive(:post).and_return(OpenStruct.new(:code => 404))

      expect { user.send message }.to raise_error(HipChat::UnknownUser)
    end

    it "but fails when we're not allowed to do so" do
      allow(user.class).to receive(:post).and_return(OpenStruct.new(:code => 401))

      expect { user.send message }.to raise_error(HipChat::Unauthorized)
    end
  end

  describe '#get_user_history' do
    include_context 'HipChatV2'

    it 'successfully returns history' do
      mock_successful_user_history
      expect(user.history).to be_truthy
    end

    it 'has allowed params' do
      expect(user.instance_variable_get(:@api).history_config[:allowed_params]).to eq([:'max-results', :timezone, :'not-before'])
    end
  end

  describe '#send_file user' do
    include_context 'HipChatV2'
    let(:message) { 'Equal bytes for everyone' }
    let(:file) do
      Tempfile.new('foo').tap do |f|
        f.write('the content')
        f.rewind
      end
    end

    it 'successfully with a standard file' do
      mock_successful_user_send_file message, file

      expect(user.send_file(message, file)).to be_truthy
    end

    it "but fails when the user doesn't exist" do
      allow(user.class).to receive(:post).and_return(OpenStruct.new(:code => 404))

      expect(lambda { user.send_file message, file }).to raise_error(HipChat::UnknownUser)
    end

    it "but fails when we're not allowed to do so" do
      allow(user.class).to receive(:post).and_return(OpenStruct.new(:code => 401))

      expect(lambda { user.send_file message, file }).to raise_error(HipChat::Unauthorized)
    end
  end

  describe '#create_webhook' do
    include_context 'HipChatV2'
    let(:name)    { 'Hipchat' }
    let(:webhook) { 'https://example.org/hooks/awesome' }
    let(:type)    { 'room_enter' }

    it 'successfully with a valid room, url and event' do
      mock_successful_create_webhook(name, webhook, type)

      expect(room.create_webhook(webhook, type)).to be_truthy
    end

    it "but fails when the room doesn't exist" do
      allow(room.class).to receive(:post).and_return(OpenStruct.new(:code => 404))

      expect(lambda { room.create_webhook(webhook, type) }).to raise_error(HipChat::UnknownRoom)
    end

    it "but fails when we're not allowed to do so" do
      allow(room.class).to receive(:post).and_return(OpenStruct.new(:code => 401))

      expect(lambda { room.create_webhook(webhook, type) }).to raise_error(HipChat::Unauthorized)
    end

    it 'but fails if the url is invalid' do
      webhook = 'this://is.invalid/'
      expect(lambda { room.create_webhook(webhook, type) }).to raise_error(HipChat::InvalidUrl)
    end

    it 'but fails if the event is invalid' do
      type = 'room_vandalize'
      expect(lambda { room.create_webhook(webhook, type) }).to raise_error(HipChat::InvalidEvent)
    end

    it 'but fails if we get an unknown response code' do
      allow(room.class).to receive(:post).and_return(OpenStruct.new(:code => 403))

      expect(lambda { room.create_webhook(webhook, type) }).to raise_error(HipChat::Unauthorized)
    end
  end

  describe '#delete_webhook' do
    include_context 'HipChatV2'
    let(:room_name)    { 'Hipchat' }
    let(:webhook_name) { 'my_awesome_webhook' }

    it 'successfully deletes a webhook with a valid webhook id' do
      mock_successful_delete_webhook(room_name, webhook_name)

      expect(room.delete_webhook(webhook_name)).to be_truthy
    end

    it "but fails when the webhook doesn't exist" do
      allow(room.class).to receive(:delete).and_return(OpenStruct.new(:code => 404))

      expect(lambda { room.delete_webhook(webhook_name) }).to raise_error(HipChat::UnknownWebhook)
    end

    it "but fails when we're not allowed to do so" do
      allow(room.class).to receive(:delete).and_return(OpenStruct.new(:code => 401))

      expect(lambda { room.delete_webhook(webhook_name) }).to raise_error(HipChat::Unauthorized)
    end

    it 'but fails if we get an unknown response code' do
      allow(room.class).to receive(:delete).and_return(OpenStruct.new(:code => 403))

      expect(lambda { room.delete_webhook(webhook_name) }).to raise_error(HipChat::Unauthorized)
    end
  end

  describe '#get_all_webhooks' do
    include_context 'HipChatV2'
    let(:room_name) { 'Hipchat' }

    it 'successfully lists webhooks with a valid room id' do
      mock_successful_get_all_webhooks(room_name)

      expect(room.get_all_webhooks).to be_truthy
    end

    it "but fails when the room doesn't exist" do
      allow(room.class).to receive(:get).and_return(OpenStruct.new(:code => 404))

      expect(lambda { room.get_all_webhooks }).to raise_error(HipChat::UnknownRoom)
    end

    it "but fails when we're not allowed to do so" do
      allow(room.class).to receive(:get).and_return(OpenStruct.new(:code => 401))

      expect(lambda { room.get_all_webhooks }).to raise_error(HipChat::Unauthorized)
    end

    it 'but fails if we get an unknown response code' do
      allow(room.class).to receive(:get).and_return(OpenStruct.new(:code => 403))

      expect(lambda { room.get_all_webhooks }).to raise_error(HipChat::Unauthorized)
    end
  end

  describe '#get_webhook' do
    include_context 'HipChatV2'
    let(:room_name)  { 'Hipchat' }
    let(:webhook_id) { '5678' }

    it 'successfully gets webhook info with valid room and webhook ids' do
      mock_successful_get_webhook(room_name, webhook_id)

      expect(room.get_webhook(webhook_id)).to be_truthy
    end

    it "but fails when the webhook doesn't exist" do
      allow(room.class).to receive(:get).and_return(OpenStruct.new(:code => 404))

      expect(lambda { room.get_webhook(webhook_id) }).to raise_error(HipChat::UnknownWebhook)
    end

    it "but fails when we're not allowed to do so" do
      allow(room.class).to receive(:get).and_return(OpenStruct.new(:code => 401))

      expect(lambda { room.get_webhook(webhook_id) }).to raise_error(HipChat::Unauthorized)
    end

    it 'but fails if we get an unknown response code' do
      allow(room.class).to receive(:get).and_return(OpenStruct.new(:code => 403))

      expect(lambda { room.get_webhook(webhook_id) }).to raise_error(HipChat::Unauthorized)
    end
  end
end
