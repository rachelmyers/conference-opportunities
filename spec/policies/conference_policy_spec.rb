require 'rails_helper'

RSpec.describe ConferencePolicy do
  let(:conference_uid) { '123' }
  let(:organizer_uid) { '987' }
  let(:conference) { Conference.create!(twitter_handle: 'policyconf', uid: conference_uid) }
  let(:user) { Organizer.create!(conference: conference, uid: organizer_uid, provider: 'twitter') }

  subject(:policy) { ConferencePolicy.new(user, conference) }

  context 'when not logged in' do
    let(:user) { nil }

    context 'when the conference has been approved by its organizer' do
      let(:conference) { Conference.create!(twitter_handle: 'policyconf', uid: conference_uid, approved_at: Time.current) }

      context 'when the conference is followed by the main account' do
        it { is_expected.to permit_action(:index) }
        it { is_expected.to permit_action(:show) }
        it { is_expected.to forbid_action(:new) }
        it { is_expected.to forbid_action(:create) }
        it { is_expected.to forbid_action(:edit) }
        it { is_expected.to forbid_action(:update) }
        it { is_expected.to forbid_action(:destroy) }
      end

      context 'when the conference was unfollowed by the main account' do
        let(:conference) { Conference.create!(twitter_handle: 'policyconf', uid: conference_uid, unfollowed_at: Time.current, approved_at: Time.current) }

        it { is_expected.to permit_action(:index) }
        it { is_expected.to forbid_action(:show) }
        it { is_expected.to forbid_action(:new) }
        it { is_expected.to forbid_action(:create) }
        it { is_expected.to forbid_action(:edit) }
        it { is_expected.to forbid_action(:update) }
        it { is_expected.to forbid_action(:destroy) }
      end
    end

    context 'when the conference has not been approved by its organizer' do
      it { is_expected.to permit_action(:index) }
      it { is_expected.to forbid_action(:show) }
      it { is_expected.to forbid_action(:new) }
      it { is_expected.to forbid_action(:create) }
      it { is_expected.to forbid_action(:edit) }
      it { is_expected.to forbid_action(:update) }
      it { is_expected.to forbid_action(:destroy) }
    end
  end

  context 'when logged in as the admin' do
    let(:user) { Organizer.create!(conference: conference, uid: '765', provider: 'twitter') }

    before do
      allow(Rails.application.config).to receive(:application_twitter_id).and_return('765')
    end

    it { is_expected.to permit_action(:index) }
    it { is_expected.to permit_action(:show) }
    it { is_expected.to permit_action(:new) }
    it { is_expected.to permit_action(:create) }
    it { is_expected.to permit_action(:edit) }
    it { is_expected.to permit_action(:update) }
    it { is_expected.to forbid_action(:destroy) }
  end

  context 'when logged in as a regular organizer' do
    let(:user) { Organizer.create!(conference: conference, uid: organizer_uid, provider: 'twitter') }

    context 'when the organizer owns the conference' do
      let(:conference_uid) { '123' }
      let(:organizer_uid) { '123' }

      it { is_expected.to permit_action(:index) }
      it { is_expected.to permit_action(:show) }
      it { is_expected.to forbid_action(:new) }
      it { is_expected.to forbid_action(:create) }
      it { is_expected.to permit_action(:edit) }
      it { is_expected.to permit_action(:update) }
      it { is_expected.to forbid_action(:destroy) }
    end

    context 'when the organizer does not own the conference' do
      let(:other_conference) { Conference.create!(twitter_handle: 'unpolicyconf', uid: '456', approved_at: Time.current) }
      let(:user) { Organizer.create!(conference: other_conference, uid: organizer_uid, provider: 'twitter') }
      let(:conference_uid) { '123' }
      let(:organizer_uid) { '987' }

      context 'when the conference has been approved by its organizer' do
        let(:conference) { Conference.create!(twitter_handle: 'policyconf', uid: conference_uid, approved_at: Time.current) }

        context 'when the conference is followed by the main account' do
          it { is_expected.to permit_action(:index) }
          it { is_expected.to permit_action(:show) }
          it { is_expected.to forbid_action(:new) }
          it { is_expected.to forbid_action(:create) }
          it { is_expected.to forbid_action(:edit) }
          it { is_expected.to forbid_action(:update) }
          it { is_expected.to forbid_action(:destroy) }
        end

        context 'when the conference was unfollowed by the main account' do
          let(:conference) { Conference.create!(twitter_handle: 'policyconf', uid: conference_uid, unfollowed_at: Time.current, approved_at: Time.current) }

          it { is_expected.to permit_action(:index) }
          it { is_expected.to forbid_action(:show) }
          it { is_expected.to forbid_action(:new) }
          it { is_expected.to forbid_action(:create) }
          it { is_expected.to forbid_action(:edit) }
          it { is_expected.to forbid_action(:update) }
          it { is_expected.to forbid_action(:destroy) }
        end
      end

      context 'when the conference has not been approved by its organizer' do
        it { is_expected.to permit_action(:index) }
        it { is_expected.to forbid_action(:show) }
        it { is_expected.to forbid_action(:new) }
        it { is_expected.to forbid_action(:create) }
        it { is_expected.to forbid_action(:edit) }
        it { is_expected.to forbid_action(:update) }
        it { is_expected.to forbid_action(:destroy) }
      end
    end
  end

  describe ConferencePolicy::Scope do
    context 'when not logged in' do
      context 'when there are no conferences' do
        specify { expect(ConferencePolicy::Scope.new(nil, Conference).resolve).to eq([]) }
      end

      context 'when there is a conference' do
        context 'when the conference is not approved' do
          let!(:conference) { Conference.create!(twitter_handle: 'policyconf', uid: conference_uid, approved_at: nil, unfollowed_at: nil) }

          specify { expect(ConferencePolicy::Scope.new(nil, Conference).resolve).to eq([]) }
        end

        context 'when the conference has been unfollowed' do
          let!(:conference) { Conference.create!(twitter_handle: 'policyconf', uid: conference_uid, approved_at: Time.current, unfollowed_at: Time.current) }

          specify { expect(ConferencePolicy::Scope.new(nil, Conference).resolve).to eq([]) }
        end

        context 'when the conference is followed and approved'do
          let!(:conference) { Conference.create!(twitter_handle: 'policyconf', uid: conference_uid, approved_at: Time.current, unfollowed_at: nil) }

          specify { expect(ConferencePolicy::Scope.new(nil, Conference).resolve).to eq([conference]) }
        end
      end
    end

    context 'when logged in as the admin' do
      let(:user) { Organizer.create!(conference: conference, uid: '765', provider: 'twitter') }

      before do
        allow(Rails.application.config).to receive(:application_twitter_id).and_return('765')
      end

      context 'when the conference is not approved' do
        let!(:conference) { Conference.create!(twitter_handle: 'policyconf', uid: conference_uid, approved_at: nil, unfollowed_at: nil) }

        specify { expect(ConferencePolicy::Scope.new(user, Conference).resolve).to eq([conference]) }
      end

      context 'when the conference has been unfollowed' do
        let!(:conference) { Conference.create!(twitter_handle: 'policyconf', uid: conference_uid, approved_at: Time.current, unfollowed_at: Time.current) }

        specify { expect(ConferencePolicy::Scope.new(user, Conference).resolve).to eq([conference]) }
      end

      context 'when the conference is followed and approved'do
        let!(:conference) { Conference.create!(twitter_handle: 'policyconf', uid: conference_uid, approved_at: Time.current, unfollowed_at: nil) }

        specify { expect(ConferencePolicy::Scope.new(user, Conference).resolve).to eq([conference]) }
      end
    end

    context 'when logged in as the organizer of the conference' do
      let(:user) { Organizer.create!(conference: conference, uid: '765', provider: 'twitter') }

      context 'when the conference is not approved' do
        let!(:conference) { Conference.create!(twitter_handle: 'policyconf', uid: conference_uid, approved_at: nil, unfollowed_at: nil) }

        specify { expect(ConferencePolicy::Scope.new(user, Conference).resolve).to eq([]) }
      end

      context 'when the conference has been unfollowed' do
        let!(:conference) { Conference.create!(twitter_handle: 'policyconf', uid: conference_uid, approved_at: Time.current, unfollowed_at: Time.current) }

        specify { expect(ConferencePolicy::Scope.new(user, Conference).resolve).to eq([]) }
      end

      context 'when the conference is followed and approved' do
        let!(:conference) { Conference.create!(twitter_handle: 'policyconf', uid: conference_uid, approved_at: Time.current, unfollowed_at: nil) }

        specify { expect(ConferencePolicy::Scope.new(user, Conference).resolve).to eq([conference]) }
      end
    end

    context 'when logged in as the organizer of another conference' do
      let(:other_uid) { '412' }
      let(:other_conference) { Conference.create!(twitter_handle: 'otherconf', uid: other_uid) }
      let(:user) { Organizer.create!(conference: other_conference, uid: other_uid, provider: 'twitter') }

      context 'when the conference is not approved' do
        let!(:conference) { Conference.create!(twitter_handle: 'policyconf', uid: conference_uid, approved_at: nil, unfollowed_at: nil) }

        specify { expect(ConferencePolicy::Scope.new(user, Conference).resolve).to eq([]) }
      end

      context 'when the conference has been unfollowed' do
        let!(:conference) { Conference.create!(twitter_handle: 'policyconf', uid: conference_uid, approved_at: Time.current, unfollowed_at: Time.current) }

        specify { expect(ConferencePolicy::Scope.new(user, Conference).resolve).to eq([]) }
      end

      context 'when the conference is followed and approved' do
        let!(:conference) { Conference.create!(twitter_handle: 'policyconf', uid: conference_uid, approved_at: Time.current, unfollowed_at: nil) }

        specify { expect(ConferencePolicy::Scope.new(user, Conference).resolve).to eq([conference]) }
      end
    end
  end
end
