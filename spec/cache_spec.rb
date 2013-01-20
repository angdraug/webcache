require File.expand_path('spec/spec_helper')

describe WebCache::Cache do
  it "is a singleton" do
    cache = WebCache::Cache.instance
    cache.should be_a_kind_of WebCache::Cache
  end

  it "can be populated with entries" do
    cache = WebCache::Cache.instance
    cache.should be_a_kind_of WebCache::Cache
    cache['test'] = 'value'
    cache['test'].should eq 'value'
  end

  it "will not grow over 5MB" do
    cache = WebCache::Cache.instance
    cache.should be_a_kind_of WebCache::Cache
    k = 'x' * 1024
    cache['test_2m'] = k * 2048
    cache['test_2m'].size.should eq 1024 * 2048

    cache['test_4m'] = k * 4096
    cache['test_4m'].should be_nil
    cache['test_2m'].size.should eq 1024 * 2048

    cache['test_6m'] = k * 6144
    cache['test_6m'].should be_nil
    cache['test_2m'].size.should eq 1024 * 2048
  end
end
